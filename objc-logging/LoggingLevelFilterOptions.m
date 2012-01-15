//
//  LoggingLevelFilterOptions.m
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingLevelFilterOptions.h"
#import "Exceptions.h"

@implementation LoggingLevelFilterOptions

- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level {
    if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
        THROW(NSInvalidArgumentException, 
              @"Level parameter is out of range of valid levels.");
    }
    return _enabledLevels[level];
}


- (void) setMinimumLevel:(enum LogMessageLevel) level {
    if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
        THROW(NSInvalidArgumentException, 
              @"Level parameter is out of range of valid levels.");
    }
    for (int i = 0; i < LogMessageLevelMaximum + 1; ++i) {
        if ( i >= level ) {
            _enabledLevels[i] = YES;
        } else {
            _enabledLevels[i] = NO;
        }
    }
}

- (void) setLevel: (enum LogMessageLevel) level shouldBeLogged:(BOOL) flag {
    if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
        THROW(NSInvalidArgumentException, 
              @"Level parameter is out of range of valid levels.");
    }
    _enabledLevels[level] = flag;
}

@end
