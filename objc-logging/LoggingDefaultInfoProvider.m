//
//  LoggingDefaultInfoProvider.m
//  mp3split
//
//  Created by Rinat Zaripov on 23.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import "LoggingDefaultInfoProvider.h"

@implementation LoggingDefaultInfoProvider {
    
}

- (id) init {
    self = [super init];
    if ( self ) {
        _tags = [[NSArray alloc] initWithObjects:
                 @"date",
                 @"end-of-line", nil];
    }
    return self;
}

- (BOOL) isThreadStatic {
    return NO;
}

- (NSArray*) getTags {
    return _tags;
}

- (NSString*) getValue:(NSString*) tag 
        withParameters:(NSDictionary*) parameters
            andMessage:(LogMessage*)message {
    if ( [tag isEqualToString:@"date"] ) {
        NSString * format = [parameters objectForKey:@"format"];
        if ( format == nil ) {
            format = @"yyyy-MM-dd HH:mm";
        }
        NSDateFormatter * formatter = 
            [[NSDateFormatter alloc] init];
        [formatter setDateFormat:format];
        //
        return [formatter stringFromDate:message.timestamp];
    }
    if ( [tag isEqualToString:@"end-of-line"] ) {
        return @"\n";
    }
    return nil;
}

@end
