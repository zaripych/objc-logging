//
//  LoggingFileTarget.h
//  objc-logging
//
//  Created by Rinat Zaripov on 01/14/12.
//  Copyright (c) 2012 Rinat Zaripov. All rights reserved.
//
#import "LoggingTarget.h"

/**
    Provides file output. Supports output file name patterns.
    Supports file size limitation.
*/
@interface LoggingFileTarget : NSObject<LoggingTarget, LoggingInfoProvidersAware> {
}

/**
    Init with default parameters.
*/
- (id) init;

/**
    Init with specified file name pattern.

    \param fileNamePattern Output file name pattern.
*/
- (id) initWithFileNamePattern:(NSString*)fileNamePattern;

/**
    Output file name pattern.

    The property allows to define output file name depending on message level, logger name and other variables
    available through info providers registered in the logging manager.
*/
@property (nonatomic, retain) NSString * outputFileNamePattern;

/**
    Tells to limit log file by size.
    
    This property defines whether to limit output file size or not. This property automatically assigned to
    YES if maximumFileSizeBytes is changed.
*/
@property (nonatomic, assign) BOOL limitFileSize;

/**
    Maximum file size in bytes.

    This parameter defines when file target should change
    file name and start writing to different file. Maximum file size will be more than
    provided value - this depends on size of messages logged. But file will not be appended
    if its size if more than this value.
*/
@property (nonatomic, assign) NSInteger maximumFileSizeBytes;

/**
    Deletes all files with specified extension older than specified period.

    \param inDirectory Folder containing log files.
    \param includeSubdirectories Defines if subdirectories should be included.
    \param fileExtension Log files extension, or empty string for all files.
    \param period Period of time used to identify old files. Files older than specified will be deleted.
*/
+ (void) deleteOldLogFiles:(NSString*)inDirectory
     includeSubDirectories:(BOOL)includeSubdirectories
             withExtension:(NSString*)
                     fileExtension olderThan:(NSTimeInterval) period;

@end
