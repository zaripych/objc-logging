//
//  Exceptions.h
//  mp3split
//
//  Created by Rinat Zaripov on 30.10.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
    Checks if debugger is attached or not.
    \returns true if debugger is currently atached to the process, false otherwise.
 */
BOOL IsDebuggerAttached(int dummy);

#ifdef DEBUG

/**
    Throw NSException with specified name and reason. Just shortens code a bit.
    \param exc Exception name. NSInvalidArgumentException or something similar.
    \param reason NSString describing reason for exception.
 */
#define THROW(a_exc, a_reason) {                     \
    NSLog(@"Throwing %@ exception because of '%@'. ", (a_exc), (a_reason)); \
    NSException * exc = [NSException exceptionWithName:(a_exc) reason:(a_reason) userInfo:nil]; \
    if ( IsDebuggerAttached(0) ) { \
        Debugger(); \
    } \
    @throw exc; \
}

#else

/**
    Throw NSException with specified name and reason. Just shortens code a bit.
    \param exc Exception name. NSInvalidArgumentException or something similar.
    \param reason NSString describing reason for exception.
 */
#define THROW(a_exc, a_reason) {                     \
    NSLog(@"Throwing %@ exception because of '%@'. ", (a_exc), (a_reason)); \
    NSException * exc = [NSException exceptionWithName:(a_exc) reason:(a_reason) userInfo:nil]; \
    @throw exc; \
}

#endif // DEBUG
