//
//  NSFileManager+Extension.h
//  MultipleDownload
//
//  Created by chuonghuynh on 9/25/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager(HMCDownloadManager)

/**
 Create directory with url if it is not existed

 @param directoryURL url of directory
 */
+ (void)createDirectory:(NSURL *)directoryURL;

/**
 Create file at URL

 @param fileURL file url to create
 @param isReplace replace file or not
 */
+ (void)createFile:(NSURL *)fileURL
           replace:(BOOL)isReplace;

/**
 Copy file to a new place

 @param source source file to move
 @param destination destination file to move
 @return error gotten
 */
+ (NSError *)copyFile:(NSURL *)source
               toFile:(NSURL *)destination;

/**
 Remove file at path

 @param filePath file path to remove
 @return error gotten
 */
+ (NSError *)removeFileAt:(NSURL *)filePath;

/**
 Get avaiable disk space of device

 @return total disk space in bytes
 */
+ (int64_t)getAvailableDiskSpace;

/**
 Get size of file in bytes

 @param fileLocation file path
 @return number of bytes of file
 */
+ (NSUInteger)getSizeOfFile:(NSURL *)fileLocation;

/**
 Make valid filename

 @param fileName filename to transform
 @return valid filename
 */
+ (NSString *)_sanitizeFileNameString:(NSString *)fileName;
@end
