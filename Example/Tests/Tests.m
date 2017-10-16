//
//  HMCDownloadManagerTests.m
//  HMCDownloadManagerTests
//
//  Created by chuonghuynh on 10/16/2017.
//  Copyright (c) 2017 Chương M. Huỳnh. All rights reserved.
//

// https://github.com/Specta/Specta
#include <Foundation/Foundation.h>
#include <HMCDownloadManager/HMCDownloadManager.h>

SpecBegin(InitialSpecs)

describe(@"Check download 100 same files", ^{
    
    int __block count = 0;
    dispatch_semaphore_t __block semaphore = dispatch_semaphore_create(0);
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [dirPaths objectAtIndex:0];
    NSURL *_destinationDir = [NSURL fileURLWithPath:docsPath];
    // Download 100 files
    for (int i = 0; i < 100; i ++) {
        [[HMCDownloadManager sharedBackgroundManager] startDownloadFromURL:[NSURL URLWithString:@"https://www.cesarsway.com/sites/newcesarsway/files/styles/large_article_preview/public/Common-dog-behaviors-explained.jpg?itok=FSzwbBoi"] progressBlock:^(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            NSLog(@"abc");
        } destination:^NSURL *(NSURL *sourceUrl, NSString *identifier) {
            CFUUIDRef udid = CFUUIDCreate(NULL);
            NSString *udidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, udid));
            
            return [_destinationDir URLByAppendingPathComponent:udidString];
        } finishBlock:^(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error) {
            if (fileLocation) count ++;
            NSLog(@"Done %d",count);
            if (count == 100) {
                dispatch_semaphore_signal(semaphore);
            }
        } queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    }
    
    // Waiting for maximum 180 s until download done
    double delayInSeconds = 180;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, popTime);
    
    // Check download done or not
    it(@"Download 100 files concurrently", ^{
        expect(count).equal(@100);
    });
});

SpecEnd

