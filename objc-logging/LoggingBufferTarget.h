//
//  LoggingCustomTarget.h
//  mp3split
//
//  Created by Rinat Zaripov on 31.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LoggingTarget.h"

/**
    Special logging target which provides internal buffer to save 
    logging messages into. Serves good when we need to display logs in UI.
    Has size limit. When messages go out of the limit the beginning of the
    buffer is trimmed.
 
    // TODO: performance? what if we have full buffer and deleteCharactersInRange 
    // called too often?
 */
@interface LoggingBufferTarget : NSObject<LoggingTarget> {
    NSMutableString * _buffer;
    NSUInteger _maximumSize;
    NSUInteger _sessionStartedAt;
    NSLock * _lock;
}

/**
    Init with specified maximum characters count.
 */
- (id) initWithMaximumSize:(NSUInteger) size;

/**
    Get all characters from the buffer.
 */
- (NSString*) getAllLogs;

/**
    Get everything from current session.
 */
- (NSString*) getSessionLogs;

/**
    Start new session. This method connected with [LoggingBufferTarget getSessionLogs] method.
 */
- (void) startNewSession;

/**
    Logs out the message.
 */
- (void) logMessage:(LogMessage*) message;

@end
