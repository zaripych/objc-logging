//
//  Logger.h
//  mp3split
//
//  Created by Rinat Zaripov on 06.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingMessage.h"
#import "Exceptions.h"

@protocol LoggerProxy 

- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level;

- (void) log:(id) logger
   withLevel:(enum LogMessageLevel) level 
  andMessage:(NSString*) message;

@end

/**
    Provides interface to log messages.
 */
@interface Logger : NSObject {
    id<LoggerProxy> _proxy;
    NSString * _name;
}

/**
    Init the logger with specified proxy.
 
    \param proxy Takes all messages of the logger.
 */
- (id) initWithProxy:(id<LoggerProxy>) proxy 
             andName:(NSString*) name;

/**
    Name of the logger.
 */
@property (nonatomic, readonly) NSString * name;

/**
    Checks if specified log level is enabled.
 
    \param level Log level to check.
 */
- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isInfoEnabled;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isDebugEnabled;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isTraceEnabled;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isWarningEnabled;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isErrorEnabled;

/**
    Checks if Info log level is enabled.
 */
- (BOOL) isFatalEnabled;

/**
    Log with specified level and formatted message.

    \param level Level of the message.
    \param message Message to log out.
 */
- (void) logWithLevel:(enum LogMessageLevel)level 
  andMessage:(NSString *)message, ...  NS_FORMAT_FUNCTION(2,3);

- (void) logInfo:(NSString*) message, ...;

- (void) logDebug:(NSString*) message, ...;

- (void) logTrace:(NSString*) message, ...;

- (void) logWarning:(NSString*) message, ...;

- (void) logError:(NSString*) message, ...;

- (void) logFatal:(NSString*) message, ...;

@end

