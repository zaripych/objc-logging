//
//  LoggingFileTarget.m
//  objc-logging
//
//  Created by Rinat Zaripov on 01/14/12.
//  Copyright (c) 2012 Rinat Zaripov. All rights reserved.
//

#import "LoggingFileTarget.h"
#import "LoggingMessage.h"
#import "Logger.h"
#import "LoggingCompiledPattern.h"

@implementation LoggingFileTarget {
@private
    NSString * _outputFileNamePattern;
    LoggingCompiledPattern * _pattern;
    NSDictionary * _providersByVariableNames;
    NSMutableDictionary * _variableValues;
    NSMutableDictionary * _filesRedirection;
    NSInteger _maximumFileSizeBytes;
    BOOL _limitFileSize;
}

@synthesize maximumFileSizeBytes = _maximumFileSizeBytes;
@synthesize limitFileSize = _limitFileSize;

- (void)useInfoProviders:(NSDictionary *)providersByVariables
               withCache:(NSMutableDictionary *)variableValues {
    _providersByVariableNames = providersByVariables;
    _variableValues = variableValues;
}

- (NSString *)getNextFileName:(NSString *)outputFileName rootDirectory:(NSString *)rootDirectory {
    int index = 0;
    // file path without index suffix:
    NSString * baseFilePath = nil;
    //
    NSString * filePath = [[outputFileName stringByDeletingPathExtension] lastPathComponent];
    NSRange range = [filePath rangeOfString:@"_"];
    while ( range.length > 0) {
        NSRange rangeSub = [filePath rangeOfString:@"_" options:NSLiteralSearch
                                                 range: NSMakeRange(range.location + range.length,
                                                         filePath.length - (range.location + range.length))];
        if ( rangeSub.length == 0 ) {
            break;
        }
    }
    if ( range.length > 0 ) {
        // last path component contains '_'
        NSString * indexString = [filePath substringFromIndex:range.location + range.length];
        NSScanner * scanner = [[NSScanner alloc] initWithString:indexString];
        if ( [scanner scanInt:&index] ) {
            NSString * testWithParsedIndex = [NSString stringWithFormat:@"%@_%d",
                            [filePath substringToIndex:range.location], index];
            // generated string should be equal to filePath now:
            if ([testWithParsedIndex isEqualToString:filePath]) {
                // yep we got index:
                baseFilePath = [rootDirectory stringByAppendingPathComponent:[filePath substringToIndex:range.location]];
            } else {
                // no, the '_' symbol found is not index preceding symbol
                baseFilePath = [outputFileName stringByDeletingPathExtension];
            }
        }
    } else {
        index = 1;
        baseFilePath = [outputFileName stringByDeletingPathExtension];
        filePath = [[baseFilePath stringByDeletingPathExtension]
                            stringByAppendingFormat:@"_%d.%@", index, [outputFileName pathExtension]];
    }
    // increment index while files exists and file size is more than limit:
    while ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        FILE * fp = 0;
        long size = 0;
        @try {
            fp = fopen([filePath UTF8String], "a+");
            if ( fp == 0) {
                continue;
            }
            fseek(fp, 0L, SEEK_END);
            ftell(fp);
        } @finally {
            fclose(fp);
        }
        if ( size < _maximumFileSizeBytes ) {
            break;
        }
        index++;
        filePath = [[baseFilePath stringByDeletingPathExtension]
                stringByAppendingFormat:@"_%d.%@", index, [outputFileName pathExtension]];
    }
    //
    return filePath;
}

- (void)logMessage:(LogMessage *)message {
    if ( _pattern == nil ) {
        NSLog(@"ERROR: Cannot log messages. File name pattern is not specified.");
        return;
    }
    // determine file name:
    NSString * outputFileName = [_pattern buildMessageUsingProviders:_providersByVariableNames
                                                        andVariables:_variableValues
                                                          andMessage:message];
    //
    NSRange range = [outputFileName rangeOfString:@"~"];
    if ( range.length > 0 && range.location == 0 ) {
        outputFileName = [outputFileName stringByExpandingTildeInPath];
    }
    // if specified file is set to be redirected?
    NSString * redirectToFileName = [_filesRedirection objectForKey:outputFileName];
    if ( redirectToFileName != nil ) {
        outputFileName = redirectToFileName;
    }
    //
    BOOL isDirectory = NO;
    NSString * rootDirectory = [outputFileName stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootDirectory
                                             isDirectory:&isDirectory]) {
        if ( !isDirectory ) {
            NSLog(@"ERROR: Cannot open output file at path '%@'. Because root folder already exists as a file.", outputFileName);
            return;
        }
    } else {
        NSError * errors = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:rootDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&errors];
        if ( errors != nil ) {
            NSLog(@"ERROR: Cannot create root folder for path '%@'. Because %@", outputFileName, errors);
        }
    }
    // TODO: buffered write? what if we write not message by message but a bulk set of messages - that may make sense.
    FILE * fp = fopen([outputFileName UTF8String], "a+");
    @try {
        if ( fp == 0 ) {
            NSLog(@"ERROR: Cannot open output file at path '%@'.", outputFileName);
            return;
        }
        fseek(fp, 0L, SEEK_END);
        if ( _limitFileSize ) {
            long size = ftell(fp);
            if ( size > _maximumFileSizeBytes ) {
                fclose(fp);
                // current file index:
                NSString * filePath = [self getNextFileName:outputFileName rootDirectory:rootDirectory];
                //
                fp = fopen([filePath UTF8String], "a+");
                if ( fp == 0 ) {
                    NSLog(@"ERROR: Cannot open output file at path '%@'.", filePath);
                    return;
                } else {
                    [_filesRedirection setObject:filePath forKey:outputFileName];
                }
            }
        }
        //
        const char * utf8string = [message.messageBuild UTF8String];
        fwrite(utf8string, sizeof(char), message.messageBuild.length, fp);
    } @finally {
        if ( fp != 0) {
            fclose(fp);
        }
    }
}

- (id)init {
    self = [super init];
    if ( self ) {
        _maximumFileSizeBytes = 100 * 1024 * 1024;
        _filesRedirection = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (id)initWithFileNamePattern:(NSString *)fileNamePattern {
    self = [super init];
    if ( self ) {
        _maximumFileSizeBytes = 100 * 1024 * 1024;
        _filesRedirection = [[NSMutableDictionary alloc] initWithCapacity:10];
        //
        [self setOutputFileNamePattern:fileNamePattern];
    }
    return self;
}


- (NSString *)outputFileNamePattern {
    return _outputFileNamePattern;
}

- (void)setOutputFileNamePattern:(NSString *)outputFileNamePattern {
    if ( outputFileNamePattern == nil ) {
        THROW(NSInvalidArgumentException, @"Output file name pattern is not initialized.");
    }
    if ( outputFileNamePattern.length == 0 ) {
        THROW(NSInvalidArgumentException, @"Output file name pattern is empty string.");
    }
    //
    if ( _outputFileNamePattern != outputFileNamePattern ) {
        if ( _outputFileNamePattern == nil || ![_outputFileNamePattern isEqualToString:outputFileNamePattern] ) {
            // still, validate:
            LoggingCompiledPattern * pattern = [[LoggingCompiledPattern alloc] initWithPattern:outputFileNamePattern];
            //
            NSArray * array = [NSArray arrayWithObjects:@"message", nil];
            if ([pattern containsOneOfVariables:array] ) {
                THROW(NSInvalidArgumentException, @"File name pattern cannot contain specific variables. "
                        @"This includes: message.");
            }
            //
            [self willChangeValueForKey:@"outputFileNamePattern"];
            //
            _outputFileNamePattern = outputFileNamePattern;
            _pattern = pattern;
            //
            [self didChangeValueForKey:@"outputFileNamePattern"];
        }
    }
}

+ (void)deleteOldLogFiles:(NSString *)inDirectory
    includeSubDirectories:(BOOL)includeSubdirectories
            withExtension:(NSString *)fileExtension olderThan:(NSTimeInterval)period {
    //
    NSDirectoryEnumerator * dir = [[NSFileManager defaultManager] enumeratorAtPath:inDirectory];
    if ( dir != nil) {
        for(NSString * path in dir) {
            NSError * error = nil;
            NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                         error:&error];
            //
            if ( error == nil && attributes != nil ) {
                if ( [attributes objectForKey:NSFileTypeDirectory] != nil && includeSubdirectories ) {
                    [LoggingFileTarget deleteOldLogFiles:path
                                   includeSubDirectories:YES
                                           withExtension:fileExtension
                                               olderThan:period];
                } else {
                    if ([[path pathExtension] isEqualToString:fileExtension]) {
                        NSDate * date = [attributes objectForKey:NSFileCreationDate];
                        NSDate * datePrev = [NSDate dateWithTimeIntervalSinceNow:-period];
                        if ([date isLessThan:datePrev]) {
                            error = nil;
                            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                            if ( error != nil ) {
                                NSLog(@"ERROR: cannot delete old log file at path '%@' with error telling %@", path, error);
                            }
                        }
                    }
                }
            } else if ( error != nil ) {
                NSLog(@"ERROR: cannot get file attributes at path '%@' with error telling %@", path, error);
            }
        }
    }
}

@end
