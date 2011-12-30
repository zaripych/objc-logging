//
//  LoggingTargetOptions.h
//  mp3split
//
//  Created by Rinat Zaripov on 11.12.11.
//  Copyright (c) 2011 Rinat Zaripov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingMessage.h"

/**
    Incapsulates target specific options.
 */
@interface LoggingTargetOptions : NSObject {
    NSString * _name;
    NSString * _messagePattern;
}

/**
    Defines target name.
 */
@property (nonatomic, strong) NSString * name;

/**
    Defines output message pattern.
 */
@property (nonatomic, strong) NSString * messagePattern;

@end
