#import "BreakTimeWindow.h"

#include "config.h"

extern const uint8_t *icon;
extern const size_t icon_len;

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

void app_main(int argc, const char *argv[], struct config *config) {
#pragma unused(config)
  [NSAutoreleasePool new];
  [NSApplication sharedApplication];

  NSData *image_data = NULL;
  if (config->appearance.icon_path) {
    image_data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:config->appearance.icon_path]];
  } else {
    image_data = [NSData dataWithBytes:icon
                                length:icon_len];
  }
  [NSApp setApplicationIconImage:[[NSImage alloc] initWithData:image_data]];
  [NSApp.dockTile display];

  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

  BreakTimeWindow *window = [[BreakTimeWindow alloc] initWithConfig:config];

  [window makeKeyAndOrderFront:nil];

  NSApplicationMain(argc, argv);
}
