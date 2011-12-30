//
//  LoggingConsoleTarget.m
//  mp3split
//
//  Created by Rinat Zaripov on 23.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingConsoleTarget.h"

@implementation LoggingConsoleTarget

- (void) logMessage:(LogMessage*) message {
    const char * cmessage = [[message messageBuild] UTF8String];
    printf ("%s", cmessage);
}

@end
