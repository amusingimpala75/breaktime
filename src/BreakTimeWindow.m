#import "BreakTimeWindow.h"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

const int mask = NSWindowStyleMaskFullSizeContentView |
                 NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                 NSWindowStyleMaskResizable;

static NSColor *colorFromRGBA(int code) {
  return [NSColor colorWithRed:((code >> 24) & 0xFF) / 255.0
                         green:((code >> 16) & 0xFF) / 255.0
                          blue:((code >> 8) & 0xFF) / 255.0
                         alpha:((code >> 0) & 0xFF) / 255.0];
}

typedef NSColor *NSColorPtr;
typedef NSDictionary *NSDictionaryPtr;

static NSString *toNSString(const char *cString) {
  return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
}

static NSFont *toNSFont(const struct font *font) {
  NSFont *ret = [NSFont fontWithName:toNSString(font->name) size:font->size];
  if (!ret) {
    printf("Invalid font: %s\n", font->name);
    exit(1);
  }
  return ret;
}

@implementation BreakTimeWindow
- (instancetype)initWithConfig:(struct config *)config {
  // Do super setup
  self = [self initWithContentRect:[NSScreen mainScreen].frame
                         styleMask:mask
                           backing:NSBackingStoreBuffered
                             defer:NO];
  self.config = config;
  self.closing = NO;
  // Let transparency work
  self.hasShadow = NO;
  self.opaque = NO;
  // Set the background color
  self.backgroundColor = colorFromRGBA(self.config->appearance.background);
  // Grid for items
  NSGridView *grid = [NSGridView gridViewWithNumberOfColumns:1 rows:2];
  self.contentView = grid;
  // Text field with the message
  {
    NSAttributedString *text = [[NSAttributedString alloc]
        initWithString:toNSString(self.config->appearance.message)
            attributes:@{
              NSFontAttributeName :
                  toNSFont(&self.config->appearance.message_font),
              NSForegroundColorAttributeName : colorFromRGBA(
                  self.config->appearance.message_font.color << 8 | 0xFF)
            }];
    NSTextField *textField = [NSTextField labelWithAttributedString:text];
    [textField setAlphaValue:0.0];
    NSGridCell *textCell = [[grid rowAtIndex:0] cellAtIndex:0];
    textCell.contentView = textField;
    textCell.xPlacement = NSGridCellPlacementCenter;
    textCell.yPlacement = NSGridCellPlacementCenter;
  }
  // Text field for the timer
  {
    self.timerTextAttributes = @{
      NSFontAttributeName : toNSFont(&self.config->appearance.timer_font),
      NSForegroundColorAttributeName :
          colorFromRGBA(self.config->appearance.timer_font.color << 8 | 0xFF)
    };
    NSAttributedString *text =
        [[NSAttributedString alloc] initWithString:@"00:00"
                                        attributes:self.timerTextAttributes];
    NSTextField *textFieldTime = [NSTextField labelWithAttributedString:text];
    [textFieldTime setAlphaValue:0.0];
    NSGridCell *timeCell = [[grid rowAtIndex:1] cellAtIndex:0];
    timeCell.contentView = textFieldTime;
    timeCell.xPlacement = NSGridCellPlacementCenter;
    timeCell.yPlacement = NSGridCellPlacementBottom;

    // Set the text row height
    [grid rowAtIndex:1].height = textFieldTime.fittingSize.height + 24.0;

    [NSTimer scheduledTimerWithTimeInterval:0.2
                                    repeats:YES
                                      block:^(NSTimer *_Nonnull timer) {
#pragma unused(timer)
                                        [self updateTime];
                                      }];
  }
  // Set the title
  [self setTitle:@"Break Time"];
  // Show the window
  [self fadeIn];
  // Center
  [self center];
  // Return the window
  return self;
}

- (void)updateTime {
  NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.shownAt];
  int minutes = (int)time / 60;
  int seconds = (int)time % 60;
  NSString *time_string =
      [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
  [[[(NSGridView *)self.contentView rowAtIndex:1] cellAtIndex:0].contentView
      setAttributedStringValue:[[NSAttributedString alloc]
                                   initWithString:time_string
                                       attributes:self.timerTextAttributes]];
  if (!self.closing &&
      ((unsigned int)minutes) >= self.config->functionality.break_duration) {
    [self close];
  }
}

- (BOOL)canBecomeKeyWindow {
  return YES;
}

- (void)close {
  self.closing = YES;
  // Fade out the window
  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext]
      setDuration:self.config->appearance.animations.window.fade_out];
  [NSAnimationContext currentContext].timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  [NSAnimationContext currentContext].completionHandler = ^{
    [super close];
  };
  [[self animator] setAlphaValue:0.0];
  [NSAnimationContext endGrouping];
  // Schedule the window to reappear
  [NSTimer
      scheduledTimerWithTimeInterval:self.config->functionality.use_duration *
                                     60
                             repeats:NO
                               block:^(NSTimer *_Nonnull timer) {
#pragma unused(timer)
                                 [NSApp activateIgnoringOtherApps:YES];
                                 [[[BreakTimeWindow alloc]
                                     initWithConfig:self.config]
                                     makeKeyAndOrderFront:nil];
                               }];
}

- (void)fadeIn {
  // Fade in the window
  [NSAnimationContext beginGrouping];
  [self setAlphaValue:0.0];
  [[NSAnimationContext currentContext]
      setDuration:self.config->appearance.animations.window.fade_in];
  [NSAnimationContext currentContext].timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
  [[self animator] setAlphaValue:1.0];
  [NSAnimationContext endGrouping];
  self.shownAt = [NSDate date];
  [self updateTime];
  // Fade in message text
  NSTextField *textField =
      [[(NSGridView *)(self.contentView) rowAtIndex:0] cellAtIndex:0]
          .contentView;
  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext]
      setDuration:self.config->appearance.animations.message.fade_in];
  [NSAnimationContext currentContext].timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
  [[textField animator] setAlphaValue:1.0];
  [NSAnimationContext endGrouping];
  // Fade in timer text
  NSTextField *textFieldTime =
      [[(NSGridView *)(self.contentView) rowAtIndex:1] cellAtIndex:0]
          .contentView;
  [NSTimer
      scheduledTimerWithTimeInterval:self.config->appearance.animations.timer
                                         .fade_in_delay
                             repeats:NO
                               block:^(NSTimer *_Nonnull timer) {
#pragma unused(timer)
                                 [NSAnimationContext beginGrouping];
                                 [[NSAnimationContext currentContext]
                                     setDuration:self.config->appearance
                                                     .animations.timer.fade_in];
                                 [[textFieldTime animator] setAlphaValue:1.0];
                                 [NSAnimationContext endGrouping];
                               }];
}
@end
