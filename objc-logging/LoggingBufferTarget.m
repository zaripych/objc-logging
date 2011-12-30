//
//  LoggingCustomTarget.m
//  mp3split
//
//  Created by Rinat Zaripov on 31.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingBufferTarget.h"

@implementation LoggingBufferTarget

- (id) initWithMaximumSize:(NSUInteger) size {
    self = [super init];
    if ( self ) {
        _maximumSize = size;
        _sessionStartedAt = 0;
        _buffer = [[NSMutableString alloc] initWithCapacity:size];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString*) getAllLogs {
    [_lock lock];
    @try {
        return [NSString stringWithString:_buffer];
    }
    @finally {
        [_lock unlock];
    }
}

- (NSString*) getSessionLogs {
    if ( _sessionStartedAt == _buffer.length ) {
        return @"";
    } else {
        return [_buffer substringFromIndex:_sessionStartedAt];
    }
}

- (void) startNewSession {
    _sessionStartedAt = _buffer.length;
}

- (void) logMessage:(LogMessage*) message {
    if ( message == nil ) {
        return;
    }
    if ( message.messageBuild == nil ) {
        return;
    }
    if ( message.messageBuild.length == 0 ) {
        return;
    }
    [_lock lock];
    @try {
        NSUInteger new_size = _buffer.length + message.messageBuild.length;
        if ( new_size > _maximumSize ) {
            //
            NSUInteger cut_count = new_size - _maximumSize;
            //
            if ( cut_count >= _buffer.length ) {
                cut_count = _buffer.length;
            } else {
                // cut up to new line:
                NSRange range = [_buffer rangeOfString:@"\n" options:NSLiteralSearch 
                                                   range:NSMakeRange(cut_count, _buffer.length - cut_count)];
                if ( range.length == 0 ) {
                    cut_count = _buffer.length;
                } else {
                    cut_count = range.location + 1;
                }
            }
            //
            [_buffer deleteCharactersInRange:NSMakeRange(0, cut_count)];
            //
            if ( _sessionStartedAt < cut_count ) {
                _sessionStartedAt = 0;
            } else {
                _sessionStartedAt = _sessionStartedAt - cut_count;
            }
        }
        //
        [_buffer appendString:message.messageBuild];
    } @finally {
        [_lock unlock];
    }
}

@end
