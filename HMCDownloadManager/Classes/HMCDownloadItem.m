//
//  HMCDownloadItem.m
//  MultipleDownload
//
//  Created by chuonghuynh on 8/17/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import "HMCDownloadItem.h"
#import "HMCDownloadCallback.h"
#import "NSFileManager+Extension.h"
#import "HMCDownloadManager.h"

#define HMCDOWNLOAD_KEY_FORMAT @"HMCDownloadItem_%@"

@interface HMCDownloadItem()

@property (strong, nonatomic)   NSURLSessionDataTask                    *downloadTask;          // download task
@property (strong, nonatomic)   NSMutableArray<HMCDownloadCallback *>   *callbacks;             // Array of progress blocks
@property (nonatomic)           dispatch_queue_t                        callBacksManagerQueue;  // Queue for callbacks operations
@property (strong, nonatomic)   NSURL                                   *tempURL;               // temp url while downloading
@property (strong, nonatomic)   NSURLSession                            *urlSession;            // URL Session
@property (strong, nonatomic)   NSURL                                   *destinationURL;       // Default destination url of item

@end

@implementation HMCDownloadItem

#pragma mark - Constructors

- (instancetype)initWithUrl:(NSURL *)url
                    session:(NSURLSession *)session
              tempDirectory:(NSURL *)tempDirectory
            destinationFile:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
              progressBlock:(void (^)(NSURL *, NSString *, int64_t, int64_t, int64_t))progressBlock
                finishBlock:(void (^)(NSURL *, NSString *, NSURL *, NSError *))finishBlock
                      queue:(dispatch_queue_t)callbackQueue {
    
    self = [self initWithActiveDownloadTask:[session dataTaskWithURL:url]
                              tempDirectory:tempDirectory
                            destinationFile:destinationFile
                              progressBlock:progressBlock
                                finishBlock:finishBlock
                                      queue:callbackQueue];
    _downloadState = HMCDownloadStatePending;
    _urlSession = session;
    
    return self;
}

- (instancetype)initWithActiveDownloadTask:(NSURLSessionDataTask *)downloadTask
                             tempDirectory:(NSURL *)tempDirectory
                           destinationFile:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
                             progressBlock:(void (^)(NSURL *, NSString *, int64_t, int64_t, int64_t))progressBlock
                               finishBlock:(void (^)(NSURL *, NSString *, NSURL *, NSError *))finishBlock
                                     queue:(dispatch_queue_t)callbackQueue {
    
#if DEBUG
    NSAssert(downloadTask, @"downloadTask must be nonnull");
    NSAssert(tempDirectory, @"Temp directory must be nonnull");
#endif
    
    self = [super init];
    
    _downloadTask = downloadTask;
    _downloadState = HMCDownloadStateDownloading;
    _totalDataLength = _receivedDataLength = 0;
    _callbacks = [[NSMutableArray alloc] init];
    _callBacksManagerQueue = dispatch_queue_create("com.vn.vng.download.callbacks", DISPATCH_QUEUE_SERIAL);
    
    
    HMCDownloadCallback *callback = [[HMCDownloadCallback alloc] initWithFinishBlock:finishBlock
                                                                destinationLocation:destinationFile
                                                                            progress:progressBlock
                                                                             inQueue:callbackQueue];
    
    // Check downloaded file to restore
    _tempURL = [self getFromUserDefaultDownloadedFileOf:downloadTask.originalRequest.URL];
    
    // Not downloaded yet, create new file to download and save path to User Default
    if (_tempURL == nil) {
        _tempURL = [self createFileURLFromTempDirectory:tempDirectory];
        [NSFileManager createFile:_tempURL replace:YES];
        [self storeToUserDefaultDownloadFilePath:_tempURL from:downloadTask.originalRequest.URL];
    }
    
    [self createDefaultDestinationUrl];
    
    dispatch_async(_callBacksManagerQueue, ^{
        [_callbacks addObject:callback];
    });
    
    return self;
}

#pragma mark - Getters

- (NSURL *)url {
    
    return _downloadTask.originalRequest.URL;
}

- (NSString *)identifier {
    
    return [NSString stringWithFormat:@"%lu",(unsigned long)_downloadTask.taskIdentifier];
}

- (NSURLSessionDataTask *)downloadTask {
    
    return _downloadTask;
}

- (NSUInteger)numberOfCallbacks {
    
    NSUInteger __block count = 0;
    dispatch_sync(_callBacksManagerQueue, ^{
        count = [_callbacks count];
    });
    return count;
}

#pragma mark - Setters

- (void)setTotalDataLength:(int64_t)totalDataLength {
    
    _totalDataLength = totalDataLength;
    uint64_t freeSpace = [NSFileManager getAvailableDiskSpace];
    if (freeSpace < _totalDataLength - _receivedDataLength && _totalDataLength > _receivedDataLength) {
        [self didFinishWithError:[NSError errorWithDomain:HMCDOWNLOADERROR_SPACE
                                                     code:HMCDOWNLOADERROR_DISK_SPACE
                                                 userInfo:@{
                                                            NSLocalizedDescriptionKey:@"Don't have enough disk space to download this file"
                                                            }]];
        [self cancel];
    }
}

#pragma mark - Utilities

/**
 Create file url from temp directory

 @param tempDirectory temp directory URL
 @return URL of temp file
 */
- (NSURL *)createFileURLFromTempDirectory:(NSURL *)tempDirectory {
    
    [NSFileManager createDirectory:tempDirectory];
    CFUUIDRef udid = CFUUIDCreate(NULL);
    NSString *udidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, udid));
    return [tempDirectory URLByAppendingPathComponent:udidString];
}

/**
 Get location downloaded file from url

 @param url source url
 @return file location
 */
- (NSURL *)getFromUserDefaultDownloadedFileOf:(NSURL *)url {
    
    return [[NSUserDefaults standardUserDefaults] URLForKey:[NSString stringWithFormat:HMCDOWNLOAD_KEY_FORMAT,url.path]];
}

/**
 Store to User Default downloaded file path

 @param filePath file path to store
 @param url url to download file
 */
- (void)storeToUserDefaultDownloadFilePath:(NSURL *)filePath
                                      from:(NSURL *)url {
    
    [[NSUserDefaults standardUserDefaults] setURL:filePath
                                           forKey:[NSString stringWithFormat:HMCDOWNLOAD_KEY_FORMAT, url.path]];
}

/**
 Remove from User Default downloaded file path

 @param url url to download file
 */
- (void)removeFromUserDefaultDownloadedFileOf:(NSURL *)url {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:HMCDOWNLOAD_KEY_FORMAT, url.path]];
}

/**
 Check server support partial download

 @param url url to request
 @return YES if server support partial download, otherwise return NO
 */
- (BOOL)checkServerSupportPartialDownload:(NSURL *)url {
    
    // Request to get data from 0-0
    NSURLRequest *request = [self getRequestFromURL:url withRangeFrom:0 to:0];
    BOOL __block result = NO;
    
    // Request to server to check
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:[[NSOperationQueue alloc] init]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (response == nil) {
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        // Check status code
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (httpResponse.statusCode == 206) {
            result = YES;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    [dataTask resume];
    double delayInSeconds = 15;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, popTime);
    return result;
}

/**
 Get request from URL with range for partial download

 @param url url to download
 @param startIndex start offset
 @param endIndex end offset, -1 when you want to download all data
 @return NSURLRequest
 */
- (NSURLRequest *)getRequestFromURL:(NSURL *)url
                      withRangeFrom:(NSUInteger)startIndex
                                 to:(NSInteger)endIndex {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    if (endIndex >= 0 && endIndex >= startIndex) {
        [request addValue:[NSString stringWithFormat:@"bytes=%lu-%ld",(unsigned long)startIndex,(long)endIndex] forHTTPHeaderField:@"Range"];
    } else {
        [request addValue:[NSString stringWithFormat:@"bytes=%lu-",(unsigned long)startIndex] forHTTPHeaderField:@"Range"];
    }
    return request;
}

/**
 Create default destination url
 */
- (void)createDefaultDestinationUrl {
    
    _destinationURL = [HMCDownloadManager.defaultDownloadDir URLByAppendingPathComponent:[_tempURL lastPathComponent]];
}

#pragma mark - Public methods

- (void)appendDownloadingTo:(NSURL *(^)(NSURL *sourceUrl, NSString *identifier))destinationFile
              progressBlock:(void (^)(NSURL *, NSString *, int64_t, int64_t, int64_t))progressBlock
                finishBlock:(void (^)(NSURL *, NSString *, NSURL *, NSError *))finishBlock
                      queue:(dispatch_queue_t)callbackQueue {
    
    HMCDownloadCallback *callback = [[HMCDownloadCallback alloc] initWithFinishBlock:finishBlock
                                                                destinationLocation:destinationFile
                                                                            progress:progressBlock
                                                                             inQueue:callbackQueue];
    dispatch_async(_callBacksManagerQueue, ^{
        [_callbacks addObject:callback];
    });
}

- (BOOL)start {
    
    if (_downloadState == HMCDownloadStateNotDownload) {
        uint64_t offset = [NSFileManager getSizeOfFile:_tempURL];
        NSURLRequest *request;
        
        // Can download partial content
        if (offset > 0 && [self checkServerSupportPartialDownload:self.url]) {
            
            request = [self getRequestFromURL:self.url withRangeFrom:offset to:-1];
            _downloadTask = [_urlSession dataTaskWithRequest:request];
            _totalDataLength = offset;
            _receivedDataLength = offset;
        } else {
            _receivedDataLength = 0;
            [NSFileManager createFile:_tempURL replace:YES];
        }
        
        [_downloadTask resume];
        _downloadState = HMCDownloadStateDownloading;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)pause {
    
    if (_downloadState == HMCDownloadStateDownloading) {
        
        [_downloadTask suspend];
        _downloadState = HMCDownloadStatePaused;
        return YES;
    }
    
    return NO;
}

- (BOOL)resume {
    
    if (_downloadState == HMCDownloadStatePaused) {
        
        [_downloadTask resume];
        
        _downloadState = HMCDownloadStateDownloading;
        return YES;
    }
    
    return NO;
}

- (BOOL)cancel {
    
    // Pause
    if (_downloadState == HMCDownloadStateDownloading) {
        
        [_downloadTask cancel];
        _downloadState = HMCDownloadStateNotDownload;
        
        // Clear task
        [self removeFromUserDefaultDownloadedFileOf:self.url];
        
        // Clear temp file
        [NSFileManager removeFileAt:self.tempURL];
        
        return YES;
    }
    
    return NO;
}

- (void)didReceiveData:(NSData *)data {
    
    if (data == nil) {
        return;
    }
    
    // Write to file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tempURL.path];
    if (fileHandle != nil) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
        
        _receivedDataLength += [data length];
    }
    
    // Call back
    dispatch_async(_callBacksManagerQueue, ^{
        
        for (HMCDownloadCallback *callback in _callbacks) {
            if (callback.progressBlock == nil) {
                
                return;
            }
            dispatch_queue_t queue = (callback.callbackQueue) ? callback.callbackQueue : dispatch_get_main_queue();
            dispatch_async(queue, ^{
                
                callback.progressBlock(self.url,self.identifier, [data length],_receivedDataLength,_totalDataLength);
            });
        }
    });
    
}

- (void)didFinishWithError:(NSError *)err {
    
    NSError *__block error = err;
    
    // Check data received
    if (error == nil) {
        
        if (_receivedDataLength < _totalDataLength) {
            error = [NSError errorWithDomain:HMCDOWNLOADERROR_UNEXPECTED_DATA
                                        code:HMCDOWNLOADERROR_LARGER
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Received data is smaller than expected"}];
        } else if (_receivedDataLength > _totalDataLength) {
            error = [NSError errorWithDomain:HMCDOWNLOADERROR_UNEXPECTED_DATA
                                        code:HMCDOWNLOADERROR_LARGER
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Received data is larger than expected"}];
        }
    }
    
    // Delete url from User Default
    [self removeFromUserDefaultDownloadedFileOf:self.url];
    
    // Callback
    dispatch_async(_callBacksManagerQueue, ^{
        
        for (HMCDownloadCallback *callback in _callbacks) {
            
            if (callback.finishDownloadingBlock == nil) {
                
                return;
            }
            
            
            // Get destination url
            NSURL *destinationURL = callback.destinationLocation(self.url, self.identifier);
            
            if (destinationURL == nil) {
                destinationURL = _destinationURL;
            }
            
            NSURL *fileLocation;
            
            // Move to destination file
            if (error == nil && destinationURL != nil) {
                
                error = [NSFileManager copyFile:self.tempURL toFile:destinationURL];
                
                if (error == nil) {
                    fileLocation = destinationURL;
                }else {
                    fileLocation = self.tempURL;
                }
            }
            
            dispatch_queue_t queue = (callback.callbackQueue) ? callback.callbackQueue : dispatch_get_main_queue();
            dispatch_async(queue,^{
                
                callback.finishDownloadingBlock(self.url, self.identifier, fileLocation, error);
            });
        }
        
        // Remove file
        [NSFileManager removeFileAt:self.tempURL];
    });
}

@end
