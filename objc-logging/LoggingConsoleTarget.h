//
//  LoggingConsoleTarget.h
//  mp3split
//
//  Created by Rinat Zaripov on 23.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingTarget.h"

/**
    Logs messages out to the console/terminal.
 */
@interface LoggingConsoleTarget : NSObject<LoggingTarget> {
    
}

/**
    Logs out the message.
 */
- (void) logMessage:(LogMessage*) message;

@end
