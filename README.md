Oh NO! Yet Another Logging Library
==================================

Introduction
------------

This is simple ObjC logging library I used in some of my projects.
It uses ARC (Automatic Reference Counting) so - if you use it too
it maybe easier to include only source code into your project.

If you don't then it's better to compile the library as framework 
and use it as dynamic library.

WHY?
----

Don't ask, just wanted to share.

How do YOU use that
-------------------

Supported targets:

 - LoggingConsoleTarget - output to console/terminal
 - LoggingBufferTarget - output to internal buffer which can be used in UI 

Here is code sample:
    
    // we have static singleton instance, but you can create your own managers:
    LoggingManager * manager = [LoggingManager defaultManager];
    
    // target is where we write logs:
    LoggingConsoleTarget * console = [[LoggingConsoleTarget alloc] init];
    
    // define name of the target and its message pattern
    LoggingTargetOptions * consoleOptions = [[LoggingTargetOptions alloc] init];
    consoleOptions.name = @"console";
    // note escaping characters:
    consoleOptions.messagePattern = @"{level} {date:format=HH\\:mm\\:ss} {logger} {message}{end-of-line}";
    //
    // rule defines what loggers where to output:
    LoggingRule * rule = [[LoggingRule alloc] init];
    rule.loggerNamePattern = @".*";
    [rule.targetNames addObject:@"console"];
    // setup:
    [manager addTarget:console 
           withOptions:consoleOptions];
    [manager addLoggingRule:rule];
    [manager setMinimumLevel:LogMessageLevelInfo];
    // create logger:
    Logger * logger = [manager getLogger:@"AAA"];
    //
    if ( [logger isLogLevelEnabled:level] ) {
         [logger logWithLevel:level 
                   andMessage:@"Hello there the world of logs!"];
    }
    // shorter syntax:
    if ( [logger isErrorEnabled] ) {
         [logger logError:@"Hello there the world of logs!"];
    }
    //

Good luck!