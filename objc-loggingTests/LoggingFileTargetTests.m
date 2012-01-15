//
//  LoggingFileTargetTests.m
//  objc-logging
//
//  Created by Rinat Zaripov on 01/15/12.
//  Copyright (c) 2012 Rinat Zaripov. All rights reserved.
//

#import "LoggingManager.h"
#import "LoggingFileTarget.h"
#import "LoggingFileTargetTests.h"

@implementation LoggingFileTargetTests

// All code under test must be linked into the Unit Test bundle
- (void) testInitEmpty {
    STAssertNotNil([[LoggingFileTarget alloc] init], @"Should be not nil.");
}

- (void) testInitWithFilePattern {
    STAssertNotNil([[LoggingFileTarget alloc] initWithFileNamePattern:@"/Library/Logs/{level}-log.log"], @"Should be not nil.");
}

- (void) testInitWithInvalidFilePattern {
    STAssertThrows([[LoggingFileTarget alloc] initWithFileNamePattern:@"/Library/Logs/{level}{message}-log.log"],
            @"File pattern contains invalid variable. Should throw exceptions here.");
    LoggingFileTarget * target = [[LoggingFileTarget alloc] initWithFileNamePattern:@"/Library/Logs/{level}-log.log"];
    STAssertNotNil(target, @"Should be not nil.");
    STAssertThrows(target.outputFileNamePattern = @"/Library/Logs/{level}{message}-log.log",
                @"File pattern contains invalid variable. Should throw exceptions here.");
}

- (void) testWrites {
    NSBundle * bundle = [NSBundle bundleForClass:[LoggingFileTargetTests class]];
    NSString * logsRoot = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/Logs"];
    NSString * logFileName = [logsRoot stringByAppendingPathComponent:@"all-logs.log"];
    //
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFileName error:nil];
    }
    //
    LoggingManager * manager = [LoggingManager defaultManager];
    [manager resetConfiguration];
    //
    LoggingFileTarget * target = [[LoggingFileTarget alloc] initWithFileNamePattern:logFileName];
    target.limitFileSize = NO;
    //
    LoggingTargetOptions * options = [[LoggingTargetOptions alloc] init];
    options.name = @"file-output";
    options.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    [manager addTarget:target
           withOptions:options];
    //
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"file-output"];
    //
    [manager addLoggingRule:rule];
    //
    [manager setMinimumLevel:LogMessageLevelTrace];
    //
    Logger * logger = [manager getLogger:@"file-output-test-logger"];
    //
    if ([logger isInfoEnabled]) {
        [logger logInfo:@"This is informational message"];
    } else {
        STFail(@"Info level should be enabled.");
    }
    //
    if ([logger isWarningEnabled]) {
        [logger logWarning:@"This is warning message."];
    } else {
        STFail(@"Warning level should be enabled.");
    }
    //
    if ([logger isErrorEnabled]) {
        [logger logError:@"This is error message."];
    } else {
        STFail(@"Error level should be enabled.");
    }
    //
    if ([logger isFatalEnabled]) {
        [logger logFatal:@"This is fatal error message."];
    } else {
        STFail(@"Fatal level should be enabled.");
    }
    //
    if ([logger isDebugEnabled]) {
        [logger logDebug:@"This is debug message."];
    } else {
        STFail(@"Debug level should be enabled.");
    }
    //
    if ([logger isTraceEnabled]) {
        [logger logTrace:@"This is trace level message."];
    } else {
        STFail(@"Trace level should be enabled.");
    }
    for (int i = 0; i < 1024 * 2; ++i ) {
        if ([logger isTraceEnabled]) {
            [logger logTrace:@"This is trace level message."];
        } else {
            STFail(@"Trace level should be enabled.");
        }
    }
    [NSThread sleepForTimeInterval:1.0f];
    //
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:logFileName], @"Log file should exists.");
    //
    NSString * contents = [NSString stringWithContentsOfFile:logFileName
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    //
    STAssertTrue([contents rangeOfString:@"INFO"].length != 0, @"INFO should exists in file.");
    STAssertTrue([contents rangeOfString:@"WARNING"].length != 0, @"WARNING should exists in file.");
    STAssertTrue([contents rangeOfString:@"ERROR"].length != 0, @"ERROR should exists in file.");
    STAssertTrue([contents rangeOfString:@"FATAL"].length != 0, @"FATAL should exists in file.");
    STAssertTrue([contents rangeOfString:@"DEBUG"].length != 0, @"DEBUG should exists in file.");
    STAssertTrue([contents rangeOfString:@"TRACE"].length != 0, @"TRACE should exists in file.");
    //
    [manager resetConfiguration];
}

- (void) testWritesWithPattern {
    NSBundle * bundle = [NSBundle bundleForClass:[LoggingFileTargetTests class]];
    NSString * logsRoot = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/Logs"];
    NSString * logFileName = [logsRoot stringByAppendingPathComponent:@"{level-lower-case}-logs.log"];
    //
    NSString * infoPath = [logsRoot stringByAppendingPathComponent:@"info-logs.log"];
    NSString * warningPath = [logsRoot stringByAppendingPathComponent:@"warning-logs.log"];
    NSString * errorPath = [logsRoot stringByAppendingPathComponent:@"error-logs.log"];
    NSString * fatalPath = [logsRoot stringByAppendingPathComponent:@"fatal-logs.log"];
    NSString * debugPath = [logsRoot stringByAppendingPathComponent:@"debug-logs.log"];
    NSString * tracePath = [logsRoot stringByAppendingPathComponent:@"trace-logs.log"];
    //
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:infoPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:warningPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:warningPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:errorPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:errorPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:fatalPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:fatalPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:debugPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:debugPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:tracePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tracePath error:nil];
    }
    //
    LoggingManager * manager = [LoggingManager defaultManager];
    [manager resetConfiguration];
    //
    LoggingFileTarget * target = [[LoggingFileTarget alloc] initWithFileNamePattern:logFileName];
    target.limitFileSize = NO;
    //
    LoggingTargetOptions * options = [[LoggingTargetOptions alloc] init];
    options.name = @"file-output";
    options.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    [manager addTarget:target
           withOptions:options];
    //
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"file-output"];
    //
    [manager addLoggingRule:rule];
    //
    [manager setMinimumLevel:LogMessageLevelTrace];
    //
    Logger * logger = [manager getLogger:@"file-output-test-logger"];
    //
    if ([logger isInfoEnabled]) {
        [logger logInfo:@"This is informational message"];
    } else {
        STFail(@"Info level should be enabled.");
    }
    //
    if ([logger isWarningEnabled]) {
        [logger logWarning:@"This is warning message."];
    } else {
        STFail(@"Warning level should be enabled.");
    }
    //
    if ([logger isErrorEnabled]) {
        [logger logError:@"This is error message."];
    } else {
        STFail(@"Error level should be enabled.");
    }
    //
    if ([logger isFatalEnabled]) {
        [logger logFatal:@"This is fatal error message."];
    } else {
        STFail(@"Fatal level should be enabled.");
    }
    //
    if ([logger isDebugEnabled]) {
        [logger logDebug:@"This is debug message."];
    } else {
        STFail(@"Debug level should be enabled.");
    }
    //
    if ([logger isTraceEnabled]) {
        [logger logTrace:@"This is trace level message."];
    } else {
        STFail(@"Trace level should be enabled.");
    }
    //
    [NSThread sleepForTimeInterval:1.0f];
    //
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:infoPath], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:warningPath], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:errorPath], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fatalPath], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:debugPath], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:tracePath], @"Log file should exists.");
    //
    NSString *contents = [NSString stringWithContentsOfFile:infoPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    STAssertTrue([contents rangeOfString:@"INFO"].length != 0, @"INFO should exists in file.");
    contents = [NSString stringWithContentsOfFile:warningPath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];
    STAssertTrue([contents rangeOfString:@"WARNING"].length != 0, @"WARNING should exists in file.");
    contents = [NSString stringWithContentsOfFile:errorPath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];
    STAssertTrue([contents rangeOfString:@"ERROR"].length != 0, @"ERROR should exists in file.");
    contents = [NSString stringWithContentsOfFile:fatalPath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];
    STAssertTrue([contents rangeOfString:@"FATAL"].length != 0, @"FATAL should exists in file.");
    contents = [NSString stringWithContentsOfFile:debugPath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];
    STAssertTrue([contents rangeOfString:@"DEBUG"].length != 0, @"DEBUG should exists in file.");
    contents = [NSString stringWithContentsOfFile:tracePath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];
    STAssertTrue([contents rangeOfString:@"TRACE"].length != 0, @"TRACE should exists in file.");
    //
    [manager resetConfiguration];
}

- (void) testRollsByFileSize {
    NSBundle * bundle = [NSBundle bundleForClass:[LoggingFileTargetTests class]];
    NSString * logsRoot = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/Logs"];
    NSString * logFileName = [logsRoot stringByAppendingPathComponent:@"all-logs.log"];
    NSString * logFileName1 = [logsRoot stringByAppendingPathComponent:@"all-logs_1.log"];
    //
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFileName error:nil];
    }
    //
    LoggingManager * manager = [LoggingManager defaultManager];
    [manager resetConfiguration];
    //
    LoggingFileTarget * target = [[LoggingFileTarget alloc] initWithFileNamePattern:logFileName];
    target.limitFileSize = YES;
    target.maximumFileSizeBytes = 1024;
    //
    LoggingTargetOptions * options = [[LoggingTargetOptions alloc] init];
    options.name = @"file-output";
    options.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    [manager addTarget:target
           withOptions:options];
    //
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"file-output"];
    //
    [manager addLoggingRule:rule];
    //
    [manager setMinimumLevel:LogMessageLevelTrace];
    //
    Logger * logger = [manager getLogger:@"file-output-test-logger"];
    //
    for (int i = 0; i < 1024 * 2.0f; ++i) {
        if ([logger isInfoEnabled]) {
            [logger logInfo:@"This is informational message only."];
        } else {
            STFail(@"This is filler message.");
        }
    }
    //
    [NSThread sleepForTimeInterval:1.0f];
    //
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:logFileName], @"Log file should exists.");
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:logFileName1], @"Log file should exists.");
    //
    [manager resetConfiguration];
}

@end
