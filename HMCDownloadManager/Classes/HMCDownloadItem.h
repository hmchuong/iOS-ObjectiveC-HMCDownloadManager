//
//  HMCDownloadItem.h
//  MultipleDownload
//
//  Created by chuonghuynh on 8/17/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import <Foundation/Foundation.h>

#define HMCDOWNLOADERROR_UNEXPECTED_DATA @"Unexpected received data"
#define HMCDOWNLOADERROR_LARGER 1
#define HMCDOWNLOADERROR_SMALLER 2

#define HMCDOWNLOADERROR_SPACE @"Not enough space"
#define HMCDOWNLOADERROR_MEMORY_SPACE 1
#define HMCDOWNLOADERROR_DISK_SPACE 2

/**
 HMCDownloadState of URL
 
 - HMCDownloadStateDownloading: Downloading from URL
 - HMCDownloadStatePausing: Pausing downloading from URL
 - HMCDownloadStateNotDownload: Not downloading from URL or have finished downloading
 */
typedef NS_ENUM( NSUInteger, HMCDownloadState) {
    HMCDownloadStateDownloading,
    HMCDownloadStatePaused,
    HMCDownloadStateNotDownload,
    HMCDownloadStatePending
};

/**
 Single download task
 */
@interface HMCDownloadItem : NSObject

#pragma mark - Properties

@property (nonatomic)int64_t totalDataLength;               // Total length of data
@property (nonatomic)int64_t receivedDataLength;            // Total length of received data
@property (nonatomic) HMCDownloadState downloadState;        // State of download

#pragma mark - Constructors

- (instancetype)init NS_UNAVAILABLE;

/**
 Init a download item

 @param url - NSURL to download
 @param session - NSURLSession to download
 @param destinationFile destination file
 @param progressBlock progress block
 @param finishBlock finish block
 @return HMCDownloadItem
 */
- (instancetype)initWithUrl:(NSURL *)url
                    session:(NSURLSession *)session
              tempDirectory:(NSURL *)tempDirectory
            destinationFile:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
              progressBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock
                finishBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error))finishBlock
                      queue:(dispatch_queue_t)callbackQueue;

/**
 Init a download item
 
 @param downloadTask download task
 @param tempDirectory temporary directory to download file
 @param destinationFile destination file
 @param progressBlock progress block
 @param finishBlock finish block
 @return HMCDownloadItem
 */
- (instancetype)initWithActiveDownloadTask:(NSURLSessionDataTask *)downloadTask
                             tempDirectory:(NSURL *)tempDirectory
                           destinationFile:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
                             progressBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock
                               finishBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error))finishBlock
                                     queue:(dispatch_queue_t)callbackQueue;

#pragma mark - Getters

/**
 Get NSURLSessionDataTask

 @return download task
 */
- (NSURLSessionDataTask *)downloadTask;

/**
 Get url source of download task

 @return url
 */
- (NSURL *)url;

/**
 Get identifier of download task

 @return - id of download task
 */
- (NSString *)identifier;

#pragma mark - Methods

/**
 Add callback to download item
 
 @param destinationFile destination directory
 @param progressBlock progress block
 @param finishBlock finish block
 */
- (void)appendDownloadingTo:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
              progressBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock
                finishBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error))finishBlock
                      queue:(dispatch_queue_t)callbackQueue;

/**
 Start downloading

 @return YES if success, otherwise return NO
 */
- (BOOL)start;

/**
 Pause downloading

 @return YES if success, otherwise return NO
 */
- (BOOL)pause;

/**
 Resume downloading

 @return YES if success, otherwise return NO
 */
- (BOOL)resume;

/**
 Cancel downloading
 @return YES if success, otherwise return NO
 */
- (BOOL)cancel;

/**
 Receive data and write to file

 @param data data received
 */
- (void)didReceiveData:(NSData *)data;

/**
 Complete download task with error

 @param error error gotten
 */
- (void)didFinishWithError:(NSError *)error;

@end
