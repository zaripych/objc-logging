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

/**
    Can be implemented by target to be aware of current info providers and variables
    calculated so far.
*/
@protocol LoggingInfoProvidersAware

/**
    Called from outside to inject additional information to the logging target.

    \param providersByVariables Dictionary of providers which can be accessed by variable names
    \param variableValues Dictionary of variables already calculated for the same message during logging
*/
- (void) useInfoProviders:(NSDictionary*)providersByVariables
                withCache:(NSMutableDictionary*)variableValues;

@end