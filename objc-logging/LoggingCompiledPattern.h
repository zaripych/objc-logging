//
//  LoggingCompiledPattern.h
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingInfoProvider.h"

/**
    Logging internal use class.
 */
@interface LoggingCompiledPattern : NSObject {
    // array of LoggingPatternPart
    NSMutableArray * _parts;
}

/**
    Initialize with specified logging pattern string. Pattern is parsed 
        immediately.
 */
- (id) initWithPattern:(NSString*) pattern;

/**
    Check if pattern contains variables which depend on thread static providers.
 */
- (BOOL) containsThreadStaticVariables:(NSDictionary*) providersByVariables;

/**
    Build message using compiled pattern and variables dictionary.
 
    \param variables Variables of variable names and their values.
 */
- (NSString*) buildMessage:(NSDictionary*) variables;

/**
    Build message using compiled pattern and providers.
 
    \param providersByVariables Dictionary of variable names associated to 
        providers.
    \param variables Mutable dictionary with values retrieved from providers
        used for caching between different buildMessage calls.
 */
- (NSString*) buildMessageUsingProviders:(NSDictionary*) providersByVariables
                            andVariables:(NSMutableDictionary*) variables
                              andMessage:(LogMessage *)message;

/**
    Retrieve values of variables using specified providers.
 
    \param providersByVariables Dictionary of variable names associated to 
        providers.
 
    \param variables Mutable dictionary with values retrieved from providers
        used to return values.
 */
- (void) retrieveValuesUsingProviders:(NSDictionary*) providersByVariables
                         andVariables:(NSMutableDictionary*) variables
                           andMessage:(LogMessage *)message
                     onlyThreadStatic:(BOOL) onlyThreadStatic;

@end
