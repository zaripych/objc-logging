#import "Logger.h"

@implementation Logger

@synthesize name = _name;

- (id) initWithProxy:(id<LoggerProxy>) proxy 
             andName:(NSString*) name {
    if ( proxy == nil ) {
        THROW(NSInvalidArgumentException, 
              @"Proxy parameter is not initialized.");
    }
    self = [super init];
    if ( self ) {
        _proxy = proxy;
        _name = name;
    }
    return self;
}

- (BOOL) isLogLevelEnabled:(enum LogMessageLevel) level {
    return [_proxy isLogLevelEnabled:level];
}

- (BOOL) isInfoEnabled {
    return [self isLogLevelEnabled:LogMessageLevelInfo];
}

- (BOOL) isDebugEnabled {
    return [self isLogLevelEnabled:LogMessageLevelDebug];
}

- (BOOL) isTraceEnabled {
    return [self isLogLevelEnabled:LogMessageLevelTrace];
}

- (BOOL) isWarningEnabled {
    return [self isLogLevelEnabled:LogMessageLevelWarning];
}

- (BOOL) isErrorEnabled {
    return [self isLogLevelEnabled:LogMessageLevelError];
}

- (BOOL) isFatalEnabled {
    return [self isLogLevelEnabled:LogMessageLevelFatal];
}

- (void) logWithLevel:(enum LogMessageLevel) level 
       andOnlyMessage:(NSString*) message {
    [_proxy log:self
      withLevel:level 
     andMessage:message];
}

- (void) logWithLevel:(enum LogMessageLevel)level 
  andMessage:(NSString *)message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [_proxy log:self
          withLevel:level 
         andMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logInfo:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelInfo 
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logDebug:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelDebug 
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logTrace:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelTrace
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logWarning:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelWarning
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logError:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelError
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

- (void) logFatal:(NSString*) message, ... {
    va_list list;
    va_start(list, message);
    @try {
        [self logWithLevel:LogMessageLevelFatal
            andOnlyMessage:[[NSString alloc] initWithFormat:message arguments:list]];
    }
    @finally {
        va_end(list);
    }
}

@end
