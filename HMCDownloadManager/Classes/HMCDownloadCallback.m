//
//  HMCDownloadCallback.m
//  MultipleDownload
//
//  Created by chuonghuynh on 9/14/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import "HMCDownloadCallback.h"

@implementation HMCDownloadCallback

- (instancetype)initWithFinishBlock:(void (^)(NSURL *, NSString *, NSURL *, NSError *))finishBlock
               destinationLocation:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationLocation
                           progress:(void (^)(NSURL *, NSString *, int64_t, int64_t, int64_t))progressBlock
                            inQueue:(dispatch_queue_t)callbackQueue {
    
    self = [super init];
    
    _finishDownloadingBlock = finishBlock;
    _destinationLocation = destinationLocation;
    _progressBlock = progressBlock;
    _callbackQueue = callbackQueue;
    
    return self;
}

@end
