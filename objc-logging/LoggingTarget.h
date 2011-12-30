//
//  LoggingTarget.h
//  mp3split
//
//  Created by Rinat Zaripov on 24.11.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingMessage.h"

/**
    Receives logging messages.
 */
@protocol LoggingTarget 

/**
    Logs message out wherever it should.
 
    \param message The message to log out.
 */
- (void) logMessage:(LogMessage*) message;

@end
