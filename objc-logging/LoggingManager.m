//
//  LoggingManager.m
//  mp3split
//
//  Created by Rinat Zaripov on 24.11.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingManager.h"
#import "LoggingCompiledPattern.h"
#import "LoggingConsoleTarget.h"
#import "LoggingLevelFilterOptions.h"
#import "LoggingDefaultInfoProvider.h"

@interface TargetConfiguration : NSObject {
@private
    id<LoggingTarget> _target;
    LoggingCompiledPattern * _pattern;
    NSString * _name;
    BOOL _infoProvidersAware;
}

@property (nonatomic, strong) id<LoggingTarget> target;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) LoggingCompiledPattern * pattern;
@property (nonatomic, readonly) BOOL infoProvidersAware;

@end

@implementation TargetConfiguration

@synthesize name = _name;
@synthesize pattern = _pattern;

- (id <LoggingTarget>)target {
    return _target;
}

- (void)setTarget:(id <LoggingTarget>)target {
    _infoProvidersAware = [(id)target conformsToProtocol:@protocol(LoggingInfoProvidersAware)];
    _target = target;
}

- (BOOL)infoProvidersAware {
    return _infoProvidersAware;
}

@end

// --------------------------------------------

@interface LoggerConfiguration : NSObject {
@private
    NSString * _name;
    Logger * _logger;
    NSMutableArray * _targets;
    BOOL _requiresThreadStatic;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) Logger * logger;
@property (nonatomic, readonly) NSMutableArray * targets;
@property (nonatomic) BOOL requiresThreadStatic;

@end

@implementation LoggerConfiguration

@synthesize name = _name;
@synthesize logger = _logger;
@synthesize targets = _targets;
@synthesize requiresThreadStatic = _requiresThreadStatic;

- (id) init  {
    self = [super init];
    if ( self ) { 
        _targets = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface LogMessageWrapper : NSObject {
@private
    LogMessage * _message;
    NSMutableDictionary * _variables;
    LoggerConfiguration * _configuration;
}

@property (nonatomic, strong) LogMessage * message;

@property (nonatomic, strong) NSMutableDictionary * variables;

@property (nonatomic, strong) LoggerConfiguration * configuration;

@end

@implementation LogMessageWrapper

@synthesize message = _message;
@synthesize variables = _variables;
@synthesize configuration = _configuration;

@end

@implementation LoggingManager {
@private
    id _levels;
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
    const NSString * _levelsAsStrings[LogMessageLevelMaximum + 1];
    const NSString * _levelsAsStringsLower[LogMessageLevelMaximum + 1];
    BOOL _throwExceptions;
#ifdef DEBUG
    double _timeTakesToLog;
#endif
}

- (id) init {
    self = [super init];
    if ( self ) {
        _lock = [[NSLock alloc] init];
        _levels = [[LoggingLevelFilterOptions alloc] init];
        _loggersByName = [[NSMutableDictionary alloc] init];
        _targetsByName = [[NSMutableDictionary alloc] init];
        _targetsConfiguration = [[NSMutableDictionary alloc] init];
        _rules = [[NSMutableArray alloc] init];
        _providers = [[NSMutableArray alloc] init];
        _providersByName = [[NSMutableDictionary alloc] init];
        _messages = [[NSMutableArray alloc] init];
        _loggingThreadCondition = [[NSCondition alloc] init];
        _loggingThreadSleeping = YES;
        _needsReconfiguration = NO;
        _shouldLog = YES;
        _throwExceptions = NO;
        //
        _levelsAsStrings[LogMessageLevelInfo] = @"INFO";
        _levelsAsStrings[LogMessageLevelDebug] = @"DEBUG";
        _levelsAsStrings[LogMessageLevelTrace] = @"TRACE";
        _levelsAsStrings[LogMessageLevelWarning] = @"WARNING";
        _levelsAsStrings[LogMessageLevelError] = @"ERROR";
        _levelsAsStrings[LogMessageLevelFatal] = @"FATAL";
        for (int i = 0; i < LogMessageLevelMaximum + 1; ++i ) {
            _levelsAsStringsLower[i] = [_levelsAsStrings[i] lowercaseString];
        }
    }
    return self;
}

static int _defaultManagerLock = 0;
static LoggingManager * _defaultManager = nil;

+ (void) configure {
    LoggingManager * manager = _defaultManager;
    //
    LoggingConsoleTarget * console = [[LoggingConsoleTarget alloc] init];
    LoggingTargetOptions * consoleOptions = [[LoggingTargetOptions alloc] init];
    consoleOptions.name = @"console";
    consoleOptions.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"console"];
    //
    [manager addTarget:console 
           withOptions:consoleOptions];
    [manager addLoggingRule:rule];
    
}

+ (LoggingManager*) defaultManager {
    if ( _defaultManager == nil ) {
        // lock:
        int result = __sync_lock_test_and_set( &_defaultManagerLock, 1 );
        while (result == 0) {
            result = __sync_lock_test_and_set( &_defaultManagerLock, 1 );
        }
        //
        @try {
            if ( _defaultManager == nil ) {
                _defaultManager = [[LoggingManager alloc] init];
                [_defaultManager addInfoProvider:
                    [[LoggingDefaultInfoProvider alloc] init]];
                //
                [_defaultManager setMinimumLevel:LogMessageLevelTrace];
                // for debugging:
                //[LoggingManager configure];
            }
        } @finally {
            // unlock:
            __sync_lock_release( &_defaultManagerLock );
        }
    }
    return _defaultManager;
}

- (void) signalStopLoggingThreads {
    NSCondition * condition = 
        self->_loggingThreadCondition;
    [condition lock];
    @try {
        _shouldLog = NO;
        _loggingThreadSleeping = NO;
        [condition broadcast];
    } @finally {
        [condition unlock];
    }
}

- (void) stopLoggingThreads {
    [self signalStopLoggingThreads];
}

- (void) resetConfiguration {
    [_lock lock];
    @try {
        //
        [_targetsByName removeAllObjects];
        [_targetsConfiguration removeAllObjects];
        //
        [_rules removeAllObjects];
        //
        [_providers removeAllObjects];
        [_providersByName removeAllObjects];
        // NOTE: do not remove loggers though
        _needsReconfiguration = NO;
    } @finally {
        [_lock unlock];
    }
    //
    [self addInfoProvider:[[LoggingDefaultInfoProvider alloc] init]];
    [self setMinimumLevel:LogMessageLevelTrace];
    //

#ifdef DEBUG
    if ( _timeTakesToLog > 0.0f ) {
        NSLog(@"Time took to log one message for last configuration: %f ticks.", (float)_timeTakesToLog);
    }
    _timeTakesToLog = 0.0f;
#endif
    
}

- (void) addTarget:(id<LoggingTarget>) target 
       withOptions:(LoggingTargetOptions*) options {
    if ( target == nil ) {
        THROW(NSInvalidArgumentException,
              @"Target argument is not initialized.");
    }
    if ( options == nil ) {
        THROW(NSInvalidArgumentException,
              @"Options argument is not initialized.");
    }
    if ( options.name == nil || options.name.length == 0 ) {
        THROW(NSInvalidArgumentException, 
              @"Name is not initialized or empty.");
    }
    [_lock lock];
    @try {
        NSString * name = options.name;
        if ( [_targetsByName objectForKey:name] != nil ) {
            THROW(NSInvalidArgumentException, 
                  @"Specified target name already in use.");
        }
        [_targetsByName setObject:target forKey:name];
        //
        TargetConfiguration * configuration = 
            [[TargetConfiguration alloc] init];
        configuration.name = options.name;
        configuration.pattern = [[LoggingCompiledPattern alloc] 
                                 initWithPattern:options.messagePattern];
        configuration.target = target;
        //
        [_targetsConfiguration setObject:configuration 
                                  forKey:options.name];
        //
        _needsReconfiguration = [_loggersByName count] > 0;
    } @finally {
        [_lock unlock];
    }
}

- (void) addLoggingRule:(LoggingRule*) rule {
    if ( rule == nil ) {
        THROW(NSInvalidArgumentException,
              @"Rule argument is not initialized.");
    }
    [_lock lock];
    @try {
        [_rules addObject:rule];
        _needsReconfiguration = [_loggersByName count] > 0;
    } @finally {
        [_lock unlock];
    }
}

- (void) addInfoProvider:(id<LoggingInfoProvider>) provider {
    if ( provider == nil ) {
        THROW(NSInvalidArgumentException,
              @"Provider argument is not initialized.");
    }
    [_lock lock];
    @try {
        [_providers addObject:provider];
        NSArray * array = [provider getTags];
        for (NSString * tag in array) {
            [_providersByName setObject:provider 
                                 forKey:tag];
        }
        _needsReconfiguration = [_loggersByName count] > 0;
    } @finally {
        [_lock unlock];
    }
}

- (void) setMinimumLevel:(enum LogMessageLevel) level {
    if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
        THROW(NSInvalidArgumentException, 
              @"Level parameter is out of range of valid levels.");
    }
    [_lock lock];
    @try {
        [(LoggingLevelFilterOptions*)_levels setMinimumLevel:level];
    } @finally {
        [_lock unlock];
    }
}

- (void) setLevel: (enum LogMessageLevel) level shouldBeLogged:(BOOL) flag {
    if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
        THROW(NSInvalidArgumentException, 
              @"Level parameter is out of range of valid levels.");
    }
    [_lock lock];
    @try {
        [(LoggingLevelFilterOptions*)_levels setLevel:level shouldBeLogged:flag];
    } @finally {
        [_lock unlock];
    }
}

- (void) configureLogger:(LoggerConfiguration*) configuration {
    if ( configuration == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Configuration argument is not initialized.");
    }
    [[configuration targets] removeAllObjects];
    //
    for (LoggingRule * rule in _rules) {
        if ( [rule appliesToLoggersWithName:configuration.name] ) {
            //
            for (NSString * targetName in rule.targetNames) {
                TargetConfiguration * targetConf = 
                    [_targetsConfiguration objectForKey:targetName];
                [[configuration targets] addObject:targetConf];
                //
                if ( [targetConf.pattern 
                      containsThreadStaticVariables:_providersByName] ) {
                    //
                    configuration.requiresThreadStatic = YES;
                }
            }
            //
        }
    }
}

- (void) reconfigureAllExistingLoggers {
    NSArray * loggerNames = [_loggersByName allKeys];
    for (NSString * loggerName in loggerNames) {
        LoggerConfiguration * loggerConf = 
            [_loggersByName objectForKey:loggerName];
        [self configureLogger:loggerConf];
    }
}

- (Logger*) getLogger:(NSString*) name {
    if ( name == nil || [name length] == 0 ) {
        THROW(NSInvalidArgumentException,
              @"Name string is not initialized or empty.");
    }
    LoggerConfiguration * configuration = nil;
    Logger * logger = nil;
    [_lock lock];
    @try {
        configuration = [_loggersByName objectForKey:name];
        if ( configuration == nil ) {
            logger = [[Logger alloc] initWithProxy:self
                                           andName:name];
            configuration = [[LoggerConfiguration alloc] init];
            configuration.name = name;
            configuration.logger = logger;
            //
            [self configureLogger:configuration];
            //
            [_loggersByName setObject:configuration forKey:name];
        }
    } @finally {
        [_lock unlock];
    }
    return configuration.logger;
}

- (void) setThrowExceptions:(BOOL) throwExceptions {
    _throwExceptions = throwExceptions;
}

- (void) doLogMessages:(id) object {
    //
#ifdef DEBUG
    UInt32 count = TickCount();
#endif
    //
    if ( _needsReconfiguration ) {
        [_lock lock];
        @try {
            if ( _needsReconfiguration ) {
                [self reconfigureAllExistingLoggers];
                _needsReconfiguration = NO;
            }
        } @finally {
            [_lock unlock];
        }
    }
    //
    NSDictionary * providersByVarName = nil;
    NSArray * messages = nil;
    [_lock lock];
    @try {
        messages = [[NSArray alloc] initWithArray:_messages];
        [_messages removeAllObjects];
        providersByVarName = 
            [[NSDictionary alloc] initWithDictionary:_providersByName];
    } @finally {
        [_lock unlock];
    }
    //
    NSMutableDictionary * variables = nil;
    //
    if ( messages != nil && [messages count] > 0 ) {
        //
        variables = [[NSMutableDictionary alloc] init];
        //
        for (LogMessageWrapper * messageWrapper in messages) {
            LogMessage * message = messageWrapper.message;
            //
            NSMutableDictionary * variablesStatic = messageWrapper.variables;
            if ( variablesStatic == nil ) {
                variablesStatic = variables;
            }
            [variablesStatic setObject:message.message forKey:@"message"];
            [variablesStatic setObject:@"\n" forKey:@"end-of-line"];
            [variablesStatic setObject:messageWrapper.configuration.logger.name
                                forKey:@"logger"];
            [variablesStatic setObject:_levelsAsStringsLower[message.level]
                                forKey:@"level-lower-case"];
            [variablesStatic setObject:_levelsAsStrings[message.level]
                                forKey:@"level"];
            //
            LoggerConfiguration * conf = messageWrapper.configuration;
            for (TargetConfiguration * targetConfiguration in [conf targets]) {
                @try {
                    NSString * messageFromPattern =
                        [[targetConfiguration pattern] buildMessageUsingProviders: providersByVarName
                                                        andVariables: variablesStatic
                                                          andMessage:message];
                    message.messageBuild = messageFromPattern;
                    //
                    id target = targetConfiguration.target;
                    if (targetConfiguration.infoProvidersAware) {
                        id<LoggingInfoProvidersAware> providersAware = target;
                        [providersAware useInfoProviders:providersByVarName
                                               withCache:variablesStatic];
                    }
                    //
                    [targetConfiguration.target logMessage:message];
                } @catch(id exc) {
                    NSLog(@"ERROR: There are some problem in logging thread when logging into target '%@'. Exception information follows: %@",
                        targetConfiguration.name, exc);
                    if ( _throwExceptions ) {
                        @throw exc;
                    }
                }
            }
            // clear variables for different messages
            [variables removeAllObjects];
        }
    }
#ifdef DEBUG
    if ( _timeTakesToLog > 0.0f ) {
        _timeTakesToLog = _timeTakesToLog + ((TickCount() - count) / (double)messages.count) / 2.0f;
    } else {
        _timeTakesToLog = ((TickCount() - count) / (double)messages.count);
    }
#endif
}

- (void) loggingRoutine:(id) sender {
    while ( _shouldLog ) {
        @try {
            [_loggingThreadCondition lock];
            @try {
                while ( _loggingThreadSleeping && _shouldLog ) {
                    [_loggingThreadCondition wait];
                }
            } @finally {
                [_loggingThreadCondition unlock];
            }
            // here we are - someone calls us to do some logging:
            [self doLogMessages:sender];
            //
        } @finally {
            // we will sleep again:
            _loggingThreadSleeping = [_messages count] == 0;
        }
    }
}

- (void) startLoggingThread {
    if ( _loggingThread == nil ) {
        [_lock lock];
        @try {
            if ( _loggingThread == nil ) {
                _loggingThread = [[NSThread alloc] initWithTarget:self 
                                                         selector:@selector(loggingRoutine:) 
                                                           object:nil];
                [_loggingThread setName:@"logging-thread"];
                [_loggingThread start];
            }
        } @finally {
            [_lock unlock];
        }
    }
}

- (void) queueMessage:(LogMessage*) message {
    //
    Logger * logger = message.logger;
    LoggerConfiguration * configuration = nil;
    NSDictionary * providersByVarName = nil;
    // safely get logger configuration
    [_lock lock];
    @try {
        configuration = 
            [_loggersByName objectForKey:logger.name];
        //
        if ( configuration.requiresThreadStatic ) {
            providersByVarName = 
                [[NSDictionary alloc] initWithDictionary:_providersByName];
        }
        //
    } @finally {
        [_lock unlock];
    }
    //
    LogMessageWrapper * wrapper =
        [[LogMessageWrapper alloc] init];
    wrapper.configuration = configuration;
    wrapper.message = message;
    // get thread static variables right here:
    if ( configuration.requiresThreadStatic ) {
        //
        NSMutableDictionary * variables = 
            [[NSMutableDictionary alloc] init];
        wrapper.variables = variables;
        //
        for (TargetConfiguration * target in configuration.targets) {
            [target.pattern retrieveValuesUsingProviders:providersByVarName 
                                            andVariables:variables 
                                              andMessage:message
                                        onlyThreadStatic:YES];
        }
    }
    //
    [_lock lock];
    @try {
        [_messages addObject:wrapper];
    } @finally {
        [_lock unlock];
    }
    // tell logging thread to process the queue:
    [_loggingThreadCondition lock];
    @try {
        _loggingThreadSleeping = NO;
        [_loggingThreadCondition broadcast];
    } @finally {
        [_loggingThreadCondition unlock];
    }
}

- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level {
    @try {
        if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
            THROW(NSInvalidArgumentException, 
                  @"Level parameter is out of range of valid levels.");
        }
        return [(LoggingLevelFilterOptions*)_levels isLogLevelEnabled:level];
    } @catch (id exc) {
        if ( _throwExceptions ) {
            @throw exc;
        } else {
            NSLog(@"Exception during logging. %@", exc);
        }
    }
}

- (void) log:(id) logger
   withLevel:(enum LogMessageLevel) level 
  andMessage:(NSString*) message {
    @try {
        if ( level < LogMessageLevelMinimum || level > LogMessageLevelMaximum ) {
            THROW(NSInvalidArgumentException, 
                  @"Level parameter is out of range of valid levels.");
        }
        if ( [(LoggingLevelFilterOptions*)_levels isLogLevelEnabled:level] ) {
            //
            if ( message == nil ) {
                message = @"";
            }
            //
            LogMessage * structure = [[LogMessage alloc] init];
            structure.message = [[NSString alloc] initWithString:message];
            structure.level = level;
            structure.timestamp = [[NSDate alloc] initWithTimeIntervalSinceNow:0.0f];
            structure.logger = logger;
            //
            [self startLoggingThread]; // start if not started
            [self queueMessage:structure];
        }
    } @catch (id exc) {
        if ( _throwExceptions ) {
            @throw exc;
        } else {
            NSLog(@"Exception during logging. %@", exc);
        }
    }
}

static Logger * getLoggerImpl(NSString * name) {
    return [[LoggingManager defaultManager] getLogger:name];
}

static int _staticLoggerLock = 0;

void getLogger(__strong Logger * * plogger, NSString * name) {
    if (*plogger == nil) {
        int result = __sync_lock_test_and_set( &_staticLoggerLock, 1 );
        while (result == 0) {
            result = __sync_lock_test_and_set( &_staticLoggerLock, 1 );
        }
        @try {
            if (*plogger == nil) {
                *plogger = getLoggerImpl(name);
            }
        } @finally {
            __sync_lock_release( &_staticLoggerLock );
        }
    }
}

@end
