//
//  HMCDownloadManager.h
//  MultipleDownload
//
//  Created by chuonghuynh on 8/17/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HMCDownloadItem.h"

#define BACKGROUND_IDENTIFIER @"com.vn.chuonghuynh.HMCDownloadManager.background"
#define DOWNLOAD_CALLBACK_QUEUE_ID "com.vn.chuonghuynh.HMCDownloadManager.callback.queue"
#define DOWNLOAD_MANAGER_QUEUE_ID "com.vn.chuonghuynh.HMCDownloadManager.queue"
#define MAXIMUM_DOWNLOAD_ITEMS 3
#define EXPIRATION_DAYS 7

/**
 Download mutiple files manager
 */
@interface HMCDownloadManager : NSObject<NSURLSessionDataDelegate, NSURLSessionDelegate>

#pragma mark - Properties

@property (nonatomic)NSTimeInterval    timeoutForRequest;      // maximum waiting time for the next data receiving. Only affect to DefaultSession
@property (nonatomic)NSTimeInterval    timeoutForResource;     // maximum life time for a download task. Affect to both BackgroundSession and DefaultSession
@property (nonatomic)unsigned int      maximumDownloadItems;   // maximum items can be downloaded concurrently

+ (NSURL *)defaultDownloadDir;

#pragma mark - Methods

- (instancetype)init NS_UNAVAILABLE;

/**
 Get shared background manager to download file, file downloaded by this manager can be still downloaded when app is in background state

 @return HMCDownloadManager
 */
+ (instancetype)sharedBackgroundManager;

/**
 Get shared default manager to download file, file downloaded by this manager is cancelled when app is in background state

 @return HMCDownloadManager
 */
+ (instancetype)sharedDefaultManager;

/**
 List of download tasks with identifier and url

 @return <ID, URL> active download tasks
 */
- (NSDictionary<NSURL *,NSString *> *) activeDownloaders;

/**
 Get downloading state of URL

 @param downloadTaskIdentifier - id of download task
 @return - State of task
 */
- (HMCDownloadState)downloadStateOf:(NSString *)downloadTaskIdentifier;

/**
 Start download from URL

 @param url of download item
 @param progressBlock block will be call when a piece of data is received
 @param destinationLocation block will be call to get destination location (nullable)
 @param finishBlock block will be call when download task is finished
 @param callbackQueue queue to callback progressBlock and finishBlock
 */
- (void)startDownloadFromURL:(NSURL *)url
               progressBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock
                 destination:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationLocation
                 finishBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error))finishBlock
                       queue:(dispatch_queue_t)callbackQueue;

/**
 Pause download task with identifier, only affect if task is downloading

 @param url - url of task
 */
- (void)pauseDownload:(NSURL *)url;

/**
 Resume download task with identifier, only affect if task is being paused
 
 @param url - url of task
 */
- (void)resumeDownload:(NSURL *)url;

/**
 Cancel download task with identifier
 
 @param url - url of task
 */
- (void)cancelDownload:(NSURL *)url;

@end
