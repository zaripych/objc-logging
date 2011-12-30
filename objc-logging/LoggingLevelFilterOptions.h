//
//  LoggingLevelFilterOptions.h
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingMessage.h"

/**
    Incapsulates information on logging levels.
 */
@interface LoggingLevelFilterOptions : NSObject {
    BOOL _enabledLevels[LogMessageLevelFatal + 1];
}

/**
    Set minimum level of logging. All levels up to this level will be enabled.
 */
- (void) setMinimumLevel:(enum LogMessageLevel) level;

/**
    Provides way to enable/disable levels one by one.

    \param level Level to switch on/off.
    \param flag Should be YES to enable level and NO to disable level.
 */
- (void) setLevel: (enum LogMessageLevel) level shouldBeLogged:(BOOL) flag;

/**
    Checks if specified logging level is enabled.
 */
- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level;

@end
