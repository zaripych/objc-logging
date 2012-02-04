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

Whats next?
-----------

 - I want configuration file support
 - more unit tests are required
 - add more info providers (library feature which extends logging patterns and variables you can use there) for example:
   - {bundle-path} - this variable will contain application bundle path, so we can use it as part of output file path
   - {thread-id}
   - more ...

How do YOU use that
-------------------


Supported targets:

 - LoggingConsoleTarget - output to console/terminal
 - LoggingBufferTarget - output to internal buffer which can be used in UI 
 - LoggingFileTarget - output to one or more file.

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
    if ( [logger isLogLevelEnabled:LogMessageLevelInfo] ) {
         [logger logWithLevel:LogMessageLevelInfo 
                   andMessage:@"Hello there the world of logs!"];
    }
    // shorter syntax:
    if ( [logger isErrorEnabled] ) {
         [logger logError:@"Hello there the world of logs!"];
    }
    //

Next sample is file output:
    
    // initialization code:
    LoggingFileTarget * target = [[LoggingFileTarget alloc] initWithFileNamePattern:@"~/Library/Logs/YourApp/{level}-log.txt"];
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
    
    // usage code:
    
    static Logger * logger = nil;
    
    - (id) init {
        self = [super init];
        if ( self ) {
            // getLogger helps to get loggers one time (singleton):
            getLogger(&logger, @"LoggerName");
        }
        return self;
    }
    
    - (void) someMethod {
        if ( [logger isInfoEnabled] ) {
            [logger logInfo:@"Hello there! %@", @"This is parameter"];
        }
    }

    - (void) someMethodWithBlocks {
        [logger logInfoUsingBlock:^(NSMutableString * message) {
            [message appendFormat:@"Hello there! %@", @"This is blocks logging interface."];
        }];
    }

    
Good luck!