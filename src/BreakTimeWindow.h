#pragma once

#include "config.h"

#import <Cocoa/Cocoa.h>

@interface BreakTimeWindow : NSWindow
@property (nonatomic, strong) NSDate *shownAt;
@property (nonatomic) bool closing;
@property (nonatomic) struct config *config;
@property (nonatomic, strong) NSDictionary *timerTextAttributes;
- (instancetype)initWithConfig:(struct config *)config;
@end
