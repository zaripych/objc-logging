//
//  LoggingManager.h
//  mp3split
//
//  Created by Rinat Zaripov on 24.11.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "LoggingMessage.h"
#import "LoggingTarget.h"
#import "LoggingInfoProvider.h"
#import "Exceptions.h"
#import "Logger.h"
#import "LoggingLevelFilterOptions.h"
#import "LoggingRule.h"
#import "LoggingTargetOptions.h"
#import "LoggingDefaultInfoProvider.h"

/**
    Factory for loggers, controls how messages are logged, provides interface
    to add additional logging targets and filter messages before they reach
    targets.
 */
@interface LoggingManager : NSObject<LoggerProxy> {
    LoggingLevelFilterOptions * _levels;
    NSMutableDictionary * _targetsByName;
    NSMutableDictionary * _targetsConfiguration;
    NSMutableDictionary * _loggersByName;
    NSMutableArray * _rules;
    NSMutableArray * _providers;
    NSMutableDictionary * _providersByName;
    NSMutableArray * _messages;
    NSThread * _loggingThread;
    BOOL _loggingThreadSleeping;
    BOOL _shouldLog;
    BOOL _needsReconfiguration;
    BOOL _needsRefreshProviders;
    NSCondition * _loggingThreadCondition;
    NSLock * _lock;
    NSString * _levelsAsStrings[LogMessageLevelFatal + 1];
    BOOL _throwExceptions;
}

/**
    Default logging manager instance.
 */
+ (LoggingManager*) defaultManager;

/**
    Call with cautios one time when application is finishing. Gracefully stops
        logging thread.
 */
- (void) stopLoggingThreads;

/**
    Remove all targets, additional info providers and rules.
 */
- (void) resetConfiguration;

/**
    Add target with specified options to the manager.
 
    \param target The target to add
    \param name Name of the target
 */
- (void) addTarget:(id<LoggingTarget>) target 
       withOptions:(LoggingTargetOptions*) options;

/**
    Add logging rule to the manager. Rules link loggers with targets.
 */
- (void) addLoggingRule:(LoggingRule*) rule;

/**
    Add information provider which helps to build reach messages.
 */
- (void) addInfoProvider:(id<LoggingInfoProvider>) provider;

/**
    Define if logging methods should throw exceptions for diagnostic purposes.
 */
- (void) setThrowExceptions:(BOOL) throwExceptions;

/**
    Set minimum level of logging. All levels up to this level will be enabled.
 */
- (void) setMinimumLevel:(enum LogMessageLevel) level;

/**
    Provides way to enable/disable levels one by one.
 
    \param level Level to switch on/off.
    \param flag Should be YES to enable level and NO to disable level.
 */
- (void) setLevel: (enum LogMessageLevel) level shouldBeLogged:(BOOL) flag;

/**
    Creates logger with specified name, or returns already created.
 
    \param name Name of the logger to create.
 */
- (Logger*) getLogger:(NSString*) name;

@end

/**
    Initializes logger reference if it is nil.
 
    This method is convinient to initialize static 
    variables with singleton logger reference.
 */
void getLogger(__strong Logger * * plogger, NSString * name);

