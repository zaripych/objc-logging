//
//  LoggingRule.h
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
    Defines where messages go for the set of loggers. Binds loggers to targets.
 */
@interface LoggingRule : NSObject {
    NSRegularExpression * _loggerNameRegex;
    NSMutableArray * _targetNames;
}

/**
    Regex defines scope of loggers the rule should be applied to.
 */
@property (nonatomic, readwrite, retain) NSString * loggerNamePattern;

/**
    The list of target names to use with the rule.
 */
@property (nonatomic, readonly) NSMutableArray * targetNames;

/**
    Add specified target name to the list of targets.
 */
- (void) addTarget:(NSString*) target;

/**
    Check if specified logger name applies to the rule.
 */
- (BOOL) appliesToLoggersWithName:(NSString*)loggerName;

@end
