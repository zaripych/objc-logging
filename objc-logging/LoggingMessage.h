//
//  LogMessage.h
//  mp3split
//
//  Created by Rinat Zaripov on 24.11.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
    Log message levels enumeration.
 */
enum LogMessageLevel {
    
    /**
        Trace level.
     */
    LogMessageLevelTrace,
    
    /**
        Debug level. Designates fine-grained informational events that are most useful to debug an application.
     */
    LogMessageLevelDebug,
    
    /**
        Info level. Designates informational messages that highlight the progress of the application at coarse-grained level.
     */
    LogMessageLevelInfo,
    /**
        Warning level. Designates potentially harmful situations.
     */
    LogMessageLevelWarning,
    
    /**
        Error level. Designates error events that might still allow the application to continue running.
     */
    LogMessageLevelError,
    
    /**
        Fatal level. Designates very severe error events that will presumably lead the application to abort.
     */
    LogMessageLevelFatal,
    
    LogMessageLevelMinimum = LogMessageLevelTrace,
    
    LogMessageLevelMaximum = LogMessageLevelFatal
};

/**
    Incapsulates information on log message.
 */
@interface LogMessage : NSObject {
}

/**
    Level of the message.
 */
@property (nonatomic) enum LogMessageLevel level;

/**
    Message send.
 */
@property (nonatomic, strong) NSString * message;

/**
    Message build using info providers and target pattern.
 */
@property (nonatomic, strong) NSString * messageBuild;

/**
    Time message was send.
 */
@property (nonatomic, strong) NSDate * timestamp;

/**
    Source of the message.
 */
@property (nonatomic, strong) id logger;

@end
