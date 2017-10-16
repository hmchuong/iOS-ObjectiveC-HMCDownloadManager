//
//  HMCDownloadCallback.h
//  MultipleDownload
//
//  Created by chuonghuynh on 9/14/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 Download callback
 */
@interface HMCDownloadCallback : NSObject

@property (copy, nonatomic)     void (^finishDownloadingBlock)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error);                // finish block to callback
@property (copy, nonatomic)     void (^progressBlock)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);                        // progress block to callback
@property (copy, nonatomic)   NSURL *(^destinationLocation)(NSURL *sourceUrl, NSString *identifier);          // destination location
@property (nonatomic)           dispatch_queue_t                callbackQueue;                  // queue for callback

/**
 Init

 @param finishBlock finish block
 @param progressBlock progress block
 @param callbackQueue call back queue
 @return instance
 */
- (instancetype)initWithFinishBlock:(void (^)(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error))finishBlock
                    destinationLocation:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationLocation
                           progress:(void (^)(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))progressBlock
                            inQueue:(dispatch_queue_t)callbackQueue;

@end
