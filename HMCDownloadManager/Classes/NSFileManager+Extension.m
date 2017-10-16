//
//  NSFileManager+Extension.m
//  MultipleDownload
//
//  Created by chuonghuynh on 9/25/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import "NSFileManager+Extension.h"

@implementation NSFileManager(HMCDownloadManager)

+ (void)createDirectory:(NSURL *)directoryURL {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Create new directory if not existed
    NSError *error;
    if (![directoryURL checkResourceIsReachableAndReturnError:&error]) {
        
        [fileManager createDirectoryAtURL:directoryURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];
    }
}

+ (void)createFile:(NSURL *)fileURL replace:(BOOL)isReplace {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Create new directory if not existed
    NSError *error;
    if (![fileURL checkResourceIsReachableAndReturnError:&error] || isReplace) {
        
        [fileManager createFileAtPath:fileURL.path
                             contents:nil
                           attributes:nil];
    }

}

+ (NSError *)copyFile:(NSURL *)source toFile:(NSURL *)destination {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error;
    if ([source checkResourceIsReachableAndReturnError:&error]) {
        
        // Check and create destination folder
        [NSFileManager createDirectory: [destination URLByDeletingLastPathComponent]];
        
        if ([destination checkResourceIsReachableAndReturnError:&error]) {
            destination = [NSURL fileURLWithPath:[destination.path stringByAppendingString:@"(1)"]];
        } else {
            error = nil;
        }
        
        // Copy item
        [fileManager copyItemAtURL:source toURL:destination error:&error];
    }
    
    return error;
}

+ (NSError *)removeFileAt:(NSURL *)filePath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    [fileManager removeItemAtURL:filePath error:&error];
    return error;
}

+ (int64_t)getAvailableDiskSpace {
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/var" error:nil];
    NSNumber *freeSpace = [attributes objectForKey:NSFileSystemFreeSize];
    
    return (freeSpace == nil) ? 0 : freeSpace.unsignedLongLongValue;
}

+ (NSUInteger)getSizeOfFile:(NSURL *)fileLocation {
    
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:fileLocation.path error:nil] fileSize];
}

+ (NSString *)_sanitizeFileNameString:(NSString *)fileName {
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}

@end
