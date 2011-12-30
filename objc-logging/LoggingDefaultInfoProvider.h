//
//  LoggingDefaultInfoProvider.h
//  mp3split
//
//  Created by Rinat Zaripov on 23.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingInfoProvider.h"

// {date:format=YYYY.mm.dd HH\:MM\:ss} - Prints date in a specified format.
// {level} - Prints level of log message.
// {logger} - Prints logger name.
// {message} - Prints message.
// {end-of-line} - Prints end of line.

/**
    Logging information provider.
 
    Used automatically by [LoggingManager defaultManager].
 */
@interface LoggingDefaultInfoProvider : NSObject<LoggingInfoProvider> {
    NSArray * _tags;
}

- (BOOL) isThreadStatic;
- (NSArray*) getTags;
- (NSString*) getValue:(NSString*) tag 
        withParameters:(NSDictionary*) parameters
            andMessage:(LogMessage *)message;

@end
