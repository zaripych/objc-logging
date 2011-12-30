//
//  LoggingInfoProvider.h
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingMessage.h"

/**
    Provides information for logging manager to fill message context variables.
    These variables can be used to structurize logging message and add additional
    information into it by defining logging pattern.
 */
@protocol LoggingInfoProvider <NSObject>

/**
    Should return YES if information is thread-dependend. In that case
    information will be retrieved in the same thread where logging was initiated.
 */
- (BOOL) isThreadStatic;

/**
    Returns unique strings specific to the provider. The tag indicates which provider
    should be used. This is a list variable names to be used in logging pattern.
 */
- (NSArray*) getTags;

/**
    Returns variable value.
 */
- (NSString*) getValue:(NSString*) tag 
        withParameters:(NSDictionary*) parameters
            andMessage:(LogMessage*)message;

@end
