//
//  LoggingRule.m
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingRule.h"
#import "Exceptions.h"

@implementation LoggingRule {
    
}

@synthesize targetNames = _targetNames;

- (id) init {
    self = [super init];
    if ( self ) {
        _targetNames = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString*) loggerNamePattern {
    if ( _loggerNameRegex != nil ) {
        return _loggerNameRegex.pattern;
    } else {
        return @"";
    }
}

- (void) setLoggerNamePattern:(NSString *)loggerNamePattern {
    if ( loggerNamePattern == nil || [loggerNamePattern length] == 0 ) {
        THROW(NSInvalidArgumentException, 
              @"Logger name pattern is not initialized or empty.");
    }
    //
    __autoreleasing NSError * error = nil;
    _loggerNameRegex = [[NSRegularExpression alloc] 
                        initWithPattern:loggerNamePattern 
                        options:0 
                        error:&error];
    if ( error != nil ) {
        THROW(NSInvalidArgumentException, 
              ([NSString stringWithFormat:@"Cannot initialize regular "
                "expression from string: %@. Error information: %@", 
                loggerNamePattern, [error description]]));
    }
}

- (BOOL) appliesToLoggersWithName:(NSString*)loggerName {
    if ( loggerName == nil || loggerName.length == 0 ) {
        THROW(NSInvalidArgumentException,
              @"Logger name is not initialized or empty.");
    }
    if ( _loggerNameRegex == nil ) {
        return NO;
    }
    NSTextCheckingResult * result = [_loggerNameRegex firstMatchInString:loggerName 
                                                                 options:0 
                                                                   range:NSMakeRange(0, loggerName.length)];
    return result.range.location == 0 && result.range.length == loggerName.length;
}

- (void) addTarget:(NSString *)targetName {
    if ( targetName == nil || targetName.length == 0 ) {
        THROW(NSInvalidArgumentException, 
              @"Target is not initialized or empty.");
    }
    [_targetNames addObject:targetName];
}

@end
