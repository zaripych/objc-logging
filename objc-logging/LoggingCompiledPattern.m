//
//  LoggingCompiledPattern.m
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingCompiledPattern.h"
#import "Exceptions.h"

@interface LoggingPatternPart : NSObject {
    NSString * _simpleString;
    NSString * _variableName;
    NSString * _variableWithParameters;
    NSDictionary * _parameters;
}

@property (nonatomic, strong) NSString * simpleString;

@property (nonatomic, strong) NSString * variableName;

@property (nonatomic, strong) NSString * variableWithParameters;

@property (nonatomic, strong) NSDictionary * parameters;

@end

@implementation LoggingPatternPart

@synthesize simpleString = _simpleString;
@synthesize parameters = _parameters;
@synthesize variableName = _variableName;
@synthesize variableWithParameters = _variableWithParameters;

@end

@implementation LoggingCompiledPattern {
    
}

- (LoggingPatternPart*) parseVariable:(NSString*) variable {
    if ( variable == nil || variable.length == 0 ) {
        THROW(NSInvalidArgumentException,
              @"Variable string parameter is not initialized or empty.");
    }
    //
    NSString * variableName = nil;
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    // do we have any parameters?
    NSRange range = [variable rangeOfString:@":"];
    if ( range.length > 0 ) {
        // parse parameters:
        variableName = [[variable substringWithRange:NSMakeRange(0, range.location)] 
                            stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        //
        NSError * error = nil;
        NSRegularExpression * variableRegex = [[NSRegularExpression alloc] initWithPattern:@"([^=:]*)[=]((([^=:\\\\])|(\\\\=)|(\\\\:)|(\\\\\\\\))+)[:]?" 
                                                                                   options:NSRegularExpressionCaseInsensitive 
                                                                                     error:&error];
        if ( error != nil ) {
            @throw [NSException exceptionWithName:NSGenericException 
                                           reason:@"Cannot create regex expression." 
                                         userInfo:nil];
        }
        //
        NSArray * matches = [variableRegex matchesInString:variable 
                                                   options:0 
                                                     range:NSMakeRange(0, variable.length)];
        //
        if ( matches != nil && matches.count > 0 ) {
            for (NSTextCheckingResult * result in matches) {
                NSRange rangeParameterName = [result rangeAtIndex:1];
                NSRange rangeParameterValue = [result rangeAtIndex:2];
                //
                NSString * name = [variable substringWithRange:rangeParameterName];
                NSString * value = [variable substringWithRange:rangeParameterValue];
                //
                if ( value != nil ) {
                    NSRange unescape = [value rangeOfString:@"\\:"];
                    if ( unescape.length > 0 ) {
                        value = [value 
                                 stringByReplacingOccurrencesOfString:@"\\:" 
                                 withString:@":"];
                    }
                    //
                    unescape = [value rangeOfString:@"\\="];
                    if ( unescape.length > 0 ) {
                        value = [value 
                                 stringByReplacingOccurrencesOfString:@"\\=" 
                                 withString:@"="];
                    }
                    //
                    unescape = [value rangeOfString:@"\\{"];
                    if ( unescape.length > 0 ) {
                        value = [value 
                                 stringByReplacingOccurrencesOfString:@"\\{" 
                                 withString:@"{"];
                    }
                    //
                    unescape = [value rangeOfString:@"\\}"];
                    if ( unescape.length > 0 ) {
                        value = [value 
                                 stringByReplacingOccurrencesOfString:@"\\}" 
                                 withString:@"}"];
                    }
                    //
                    unescape = [value rangeOfString:@"\\\\"];
                    if ( unescape.length > 0 ) {
                        value = [value 
                                 stringByReplacingOccurrencesOfString:@"\\\\" 
                                 withString:@"\\"];
                    }
                }
                //
                [dictionary setObject:value
                               forKey:name];
            }
        }
    } else {
        // no parameters
        variableName = variable;
    }
    //
    LoggingPatternPart * marker = [[LoggingPatternPart alloc] init];
    marker.variableName = variableName;
    marker.parameters = dictionary;
    marker.variableWithParameters = variable;
    //
    return marker;
}

- (id) initWithPattern:(NSString*) pattern {
    if ( pattern == nil || pattern.length == 0 ) {
        THROW(NSInvalidArgumentException,
              @"Patter string argument is not initialized or empty.");
    }
    //
    self = [super init];
    if ( self ) {
        NSError * error = nil;
        // {var}
        NSRegularExpression * variableRegex = [[NSRegularExpression alloc] initWithPattern:@"[{]((([^{}])|(([\\\\][{])|([\\\\][}])))*)([^\\\\{]|([\\\\][{]))[}]" 
                                                              options:NSRegularExpressionCaseInsensitive 
                                                                error:&error];
        if ( error != nil ) {
            @throw [NSException exceptionWithName:NSGenericException 
                                           reason:@"Cannot create regex expression." 
                                         userInfo:nil];
        }
        //
        _parts = [[NSMutableArray alloc] init];
        //
        NSArray * matches = [variableRegex matchesInString:pattern 
                                                    options:0 
                                                      range:NSMakeRange(0, pattern.length)];
        //
        NSUInteger cursor = 0;
        if ( matches != nil && matches.count > 0 ) {
            for (NSTextCheckingResult * result in matches) {
                // add non-parseable text:
                if ( result.range.location != cursor ) {
                    LoggingPatternPart * simple = [[LoggingPatternPart alloc] init];
                    simple.simpleString = [pattern substringWithRange:
                                           NSMakeRange(cursor, result.range.location - cursor)];
                    [_parts addObject:simple];
                }
                // add variable:
                NSString * fullVariable = [pattern substringWithRange:
                                           NSMakeRange(result.range.location + 1, result.range.length - 2)];
                LoggingPatternPart * var = [self parseVariable:fullVariable];
                if ( var == nil ) {
                    THROW(NSInvalidArgumentException,
                          @"Cannot parse variable.");
                }
                [_parts addObject:var];
                //
                cursor = result.range.location + result.range.length;
            }
            if ( cursor != pattern.length ) {
                // process last:
                LoggingPatternPart * simple = [[LoggingPatternPart alloc] init];
                simple.simpleString = [pattern substringWithRange:
                                       NSMakeRange(cursor, pattern.length - cursor)];
                [_parts addObject:simple];
            }
        } else {
            LoggingPatternPart * simple = [[LoggingPatternPart alloc] init];
            simple.simpleString = pattern;
            [_parts addObject:simple];
        }
    }
    return self;
}

- (BOOL)containsVariable:(NSString *)variableName {
    for (LoggingPatternPart * part in _parts) {
        if ( part.simpleString == nil ) {
            if ([part.variableName isEqualToString:variableName]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) containsOneOfVariables:(NSArray*) variableNames {
    for (LoggingPatternPart * part in _parts) {
        if ( part.simpleString == nil ) {
            for (NSString * varName in variableNames) {
                if ([part.variableName isEqualToString:varName]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (NSString*) buildMessage:(NSDictionary*) variables {
    NSMutableString * outString = [[NSMutableString alloc] init];
    for (LoggingPatternPart * part in _parts) {
        if ( part.simpleString != nil ) {
            [outString appendString:part.simpleString];
        } else {
            id value = [variables objectForKey:part.variableName];
            if ( value != nil ) {
                [outString appendString:[value description]];
            } else {
                [outString appendString:part.variableName];
            }
        }
    }
    return outString;
}

- (NSString*) buildMessageUsingProviders:(NSDictionary*) providersByVariables
                            andVariables:(NSMutableDictionary*) variables
                              andMessage:(LogMessage *)message {
    if ( providersByVariables == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Providers argument is not initialized.");
    }
    if ( variables == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Variables argument is not initialized.")
    }
    //
    NSMutableString * outString = [[NSMutableString alloc] init];
    for (LoggingPatternPart * part in _parts) {
        if ( part.simpleString != nil ) {
            [outString appendString:part.simpleString];
        } else {
            // try get cached variable value
            NSString * variableValue = [variables objectForKey:part.variableWithParameters];
            if ( variableValue == nil ) {
                // if no value - get it using provider
                id value = [providersByVariables objectForKey:part.variableName];
                if ( value != nil ) {
                    id<LoggingInfoProvider> provider = value;
                    variableValue = [provider getValue:part.variableName 
                                        withParameters:part.parameters
                                            andMessage:message];
                    [variables setObject:variableValue 
                                  forKey:part.variableWithParameters];
                    [outString appendString:variableValue];
                } else {
                    [outString appendString:@"{"];
                    [outString appendString:part.variableName];
                    [outString appendString:@"}"];
                }
            } else {
                [outString appendString:variableValue];
            }
        }
    }
    return outString;
}

- (BOOL) containsThreadStaticVariables:(NSDictionary*) providersByVariables {
    if ( providersByVariables == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Providers argument is not initialized.");
    }
    for (LoggingPatternPart * part in _parts) {
        if ( part.simpleString == nil ) {
            id value = [providersByVariables objectForKey:part.variableName];
            if ( value != nil ) {
                id<LoggingInfoProvider> provider = value;
                if ( [provider isThreadStatic] ) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void) retrieveValuesUsingProviders:(NSDictionary*) providersByVariables
                         andVariables:(NSMutableDictionary*) variables
                           andMessage:(LogMessage *)message
                     onlyThreadStatic:(BOOL) onlyThreadStatic {
    if ( providersByVariables == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Providers argument is not initialized.");
    }
    if ( variables == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Variables argument is not initialized.")
    }
    //
    if ( onlyThreadStatic ) {
        for (LoggingPatternPart * part in _parts) {
            if ( part.simpleString == nil ) {
                id value = [providersByVariables objectForKey:part.variableName];
                if ( value != nil ) {
                    id<LoggingInfoProvider> provider = value;
                    if ( [provider isThreadStatic] ) {
                        NSString * variableValue = [provider getValue:part.variableName 
                                                       withParameters:part.parameters
                                                           andMessage:message];
                        [variables setObject:variableValue 
                                      forKey:part.variableWithParameters];
                    }
                }
            }
        }
    } else {
        for (LoggingPatternPart * part in _parts) {
            if ( part.simpleString == nil ) {
                // try get cached variable value
                NSString * variableValue = [variables objectForKey:part.variableWithParameters];
                if ( variableValue == nil ) {
                    // if no value - get it using provider
                    id value = [providersByVariables objectForKey:part.variableName];
                    if ( value != nil ) {
                        id<LoggingInfoProvider> provider = value;
                        variableValue = [provider getValue:part.variableName 
                                            withParameters:part.parameters
                                                andMessage:message];
                        [variables setObject:variableValue 
                                      forKey:part.variableWithParameters];
                    }
                }
            }
        }
    }
}

@end
