//
//  objc_loggingTests.m
//  objc-loggingTests
//
//  Created by Rinat Zaripov on 31.12.11.
//  Copyright (c) 2011 DZ. All rights reserved.
//

#import "objc_loggingTests.h"
#import "LoggingCompiledPattern.h"
#import "LoggingManager.h"
#import "LoggingConsoleTarget.h"
#import "LoggingBufferTarget.h"

@implementation objc_loggingTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testLoggingCompiledPattern {
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    LoggingCompiledPattern * pattern = 
    [[LoggingCompiledPattern alloc] 
     initWithPattern:@"DATE:{date:format=YYYY/MM/dd}-MESSAGE:{message}"];
    //
    [dic setObject:@"30.11.84" forKey:@"date"];
    [dic setObject:@"warning" forKey:@"message"];
    //
    NSString * value = [pattern buildMessage:dic];
    STAssertTrue([value isEqualToString:
                  @"DATE:30.11.84-MESSAGE:warning"], 
                 @"Strings should be equal.");
}

// no special asserts here:
- (void) testLoggingTargetsWorkFine {
    LoggingManager * manager = [LoggingManager defaultManager];
    [manager resetConfiguration];
    //
    LoggingConsoleTarget * console = [[LoggingConsoleTarget alloc] init];
    LoggingTargetOptions * consoleOptions = [[LoggingTargetOptions alloc] init];
    consoleOptions.name = @"console";
    consoleOptions.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    LoggingBufferTarget * buffer = [[LoggingBufferTarget alloc] initWithMaximumSize:1024 * 10];
    LoggingTargetOptions * bufferOptions = [[LoggingTargetOptions alloc] init];
    bufferOptions.name = @"buffer";
    bufferOptions.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}?{end-of-line}";
    //
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"console"];
    [rule.targetNames addObject:@"buffer"];
    //
    [manager addTarget:console 
           withOptions:consoleOptions];
    [manager addTarget:buffer 
           withOptions:bufferOptions];
    [manager addLoggingRule:rule];
    [manager setMinimumLevel:LogMessageLevelInfo];
    //
    Logger * logger = [manager getLogger:@"AAA"];
    //
    double logAverage = 0.0f;
    //
    for (int i = 0; i < 1000; i ++ ) {
        int level = LogMessageLevelMinimum + rand() % LogMessageLevelMaximum;
        //
        BOOL logged = NO;
        UInt32 tickCountStart = TickCount();
        if ( [logger isLogLevelEnabled:level] ) {
            logged = YES;
            [logger logWithLevel:level 
                      andMessage:@"Hello there the world of logs!"];
        }
        UInt32 tickCountEnd = TickCount();
        //
        if ( logged ) {
            if ( logAverage == 0.0f ) {
                logAverage = tickCountEnd - tickCountStart;
            } else {
                logAverage = logAverage + (tickCountEnd - tickCountStart) / 2.0f;
            }
        }
    }
    //
    logger = [manager getLogger:@"ZZZ"];
    //
    for (int i = 0; i < 1000; i ++ ) {
        int level = LogMessageLevelMinimum + rand() % LogMessageLevelMaximum;
        if ( [logger isLogLevelEnabled:level] ) {
            [logger logWithLevel:level 
                      andMessage:@"Hello there the world of logs!"];
        }
    }
    //
    [NSThread sleepForTimeInterval:2];
    //
    NSLog(@"\nAverage ticks required for log* calls:%f\n", logAverage);
    //
}

@end
