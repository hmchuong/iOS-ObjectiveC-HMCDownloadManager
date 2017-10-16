//
//  HMCDownloadManager.m
//  MultipleDownload
//
//  Created by chuonghuynh on 8/17/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import "HMCDownloadManager.h"
#import "NSFileManager+Extension.h"
#import "NSDate+Extension.h"

@interface HMCDownloadManager()

@property (strong, nonatomic)   NSURLSession                   *urlSession;
@property (strong, nonatomic)   NSMutableDictionary            *downloadItemsDict;
@property (strong, nonatomic)   NSMutableArray                 *downloadOrder;
@property (strong, nonatomic)   NSURL                          *tempDir;
@property (nonatomic)           unsigned int                    activeDownloadCounter;
@property (nonatomic)           dispatch_queue_t                downloadItemManageQueue;

@end

@implementation HMCDownloadManager

#pragma mark - Life cycle

- (instancetype)initDefaultSession {
    
    self = [super init];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    [self setup];
    
    return self;
}

- (instancetype)initBackgroundSession {
    
    
    self = [super init];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKGROUND_IDENTIFIER];
    _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
 
    [self setup];
    
    return self;
}

+ (instancetype)sharedDefaultManager {
    
    static HMCDownloadManager *defaultDownloadManager;
    static dispatch_once_t onceDefaultToken;
    dispatch_once(&onceDefaultToken, ^{
        
        defaultDownloadManager = [[HMCDownloadManager alloc] initDefaultSession];
    });
    
    return defaultDownloadManager;
}

+ (instancetype)sharedBackgroundManager {
    
    static HMCDownloadManager *backgroundDownloadManager;
    static dispatch_once_t onceBackgroundToken;
    dispatch_once(&onceBackgroundToken, ^{
        
        backgroundDownloadManager = [[HMCDownloadManager alloc] initBackgroundSession];
    });
    
    return backgroundDownloadManager;
}

/**
 Setup handler when app will terminate, delete temp files of last session
 */
- (void)setup {
    
    _downloadItemsDict = [[NSMutableDictionary alloc] init];
    _downloadOrder = [[NSMutableArray alloc] init];
    _downloadItemManageQueue = dispatch_queue_create(DOWNLOAD_MANAGER_QUEUE_ID, DISPATCH_QUEUE_SERIAL);
    _maximumDownloadItems = MAXIMUM_DOWNLOAD_ITEMS;
    _activeDownloadCounter = 0;
    
    // Create temp directory to store downloading files
    [self checkAndCreateTempDirectory];
    
    // Run background thread to clean expired files
    [self deleteOldFiles];
    
    // Cancel all tasks when app terminated
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deallocURLSession)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    // Clear session
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [_urlSession getTasksWithCompletionHandler:^(NSArray *tasks, NSArray *uploadTasks, NSArray *downloadTasks){
        dispatch_async(_downloadItemManageQueue, ^{
            
            for (NSURLSessionDataTask *task in tasks) {
                
                [task cancel];
            }
            dispatch_semaphore_signal(semaphore);
        });
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

/**
 Dealloc URL session
 */
- (void)deallocURLSession {
    
    [_urlSession invalidateAndCancel];
}

#pragma mark - Setters

- (void)setTimeoutForRequest:(NSTimeInterval)timeoutForRequest {
    
    _timeoutForRequest = timeoutForRequest;
    _urlSession.configuration.timeoutIntervalForRequest = timeoutForRequest;
}

- (void)setTimeoutForResource:(NSTimeInterval)timeoutForResource {
    
    _timeoutForResource = timeoutForResource;
    _urlSession.configuration.timeoutIntervalForResource = timeoutForResource;
}

- (void)setMaximumDownloadItems:(unsigned int)maximumDownloadItems {
    
    _maximumDownloadItems = maximumDownloadItems;
    [self balanceDownloadingItems];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    // Set expected content length
    HMCDownloadItem *downloadItem = _downloadItemsDict[dataTask.originalRequest.URL];
    if (downloadItem != nil) {
        int64_t total = response.expectedContentLength;
        downloadItem.totalDataLength = (total + downloadItem.totalDataLength);
    }
    
    completionHandler(NSURLSessionResponseAllow);
    
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // Call HMCDownloadItem to receive data
    HMCDownloadItem *downloadItem = _downloadItemsDict[dataTask.originalRequest.URL];
    if (downloadItem != nil) {
        [downloadItem didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    HMCDownloadItem *downloadItem = _downloadItemsDict[task.originalRequest.URL];
    if (downloadItem != nil && downloadItem.downloadState != HMCDownloadStatePaused) {
        
        // Update active download counter
        if (downloadItem.downloadState == HMCDownloadStateDownloading) {
            _activeDownloadCounter --;
        }
        
        // Finish task
        [downloadItem didFinishWithError:error];
        
        // Remove task
        dispatch_async(_downloadItemManageQueue, ^{
            [_downloadItemsDict removeObjectForKey:downloadItem.url];
            [_downloadOrder removeObject:downloadItem.url];

        });
    }
    
    
    // Balance downloading
    [self balanceDownloadingItems];
}

#pragma mark - Public methods

+ (NSURL *)defaultDownloadDir {
    
    static NSURL *defaultDownloadDir;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsPath = [dirPaths objectAtIndex:0];
        defaultDownloadDir = [[NSURL fileURLWithPath:docsPath] URLByAppendingPathComponent:@"HMCDownloadManager_downloaded"];
        
        [NSFileManager createDirectory:defaultDownloadDir];
    });
    
    return defaultDownloadDir;
}

- (NSDictionary<NSURL *,NSString *> *)activeDownloaders {
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    for (NSURL *url in [_downloadItemsDict allKeys]) {
        
        result[url] = [(HMCDownloadItem *)_downloadItemsDict[url] identifier];
    }
    return result;
}

- (HMCDownloadState)downloadStateOf:(NSURL *)url {
    
    if (_downloadItemsDict[url] != nil) {
        return ((HMCDownloadItem *)_downloadItemsDict[url]).downloadState;
    }
    return HMCDownloadStateNotDownload;
}

- (void)startDownloadFromURL:(NSURL *)url
               progressBlock:(void (^)(NSURL *, NSString *, int64_t, int64_t, int64_t))progressBlock
                 destination:(NSURL *(^)(NSURL *, NSString *))destinationLocation
                 finishBlock:(void (^)(NSURL *, NSString *, NSURL *, NSError *))finishBlock
                       queue:(dispatch_queue_t)callbackQueue {
    
    // Check existed download from url
    HMCDownloadItem *__block task;
    dispatch_sync(_downloadItemManageQueue, ^{
        for (HMCDownloadItem *item in [_downloadItemsDict allValues]) {
            if ([item.url isEqual:url]) {
                [item appendDownloadingTo:destinationLocation
                            progressBlock:progressBlock
                              finishBlock:finishBlock
                                    queue:callbackQueue];
                task = item;
            }
        }
    });
    
    if (task != nil) {
        return;
    }
    
    // Create new task
    task = [[HMCDownloadItem alloc] initWithUrl:url
                                        session:_urlSession
                                  tempDirectory:_tempDir
                                destinationFile:destinationLocation
                                  progressBlock:progressBlock
                                    finishBlock:finishBlock
                                          queue:callbackQueue];
    
    dispatch_async(_downloadItemManageQueue, ^{
        
        // Add to dictionary
        _downloadItemsDict[task.url] = task;
        
        // Add to order array
        [_downloadOrder addObject:task.url];
    });
    
    // Balance downloading
    [self balanceDownloadingItems];
    
    return;
}

- (void)pauseDownload:(NSURL *)url {
    
    HMCDownloadItem *task = _downloadItemsDict[url];
    
    if (task == nil) {
        
        return;
    }
    
    // Update active download counter
    if ([task pause]) {
        _activeDownloadCounter --;
    }
    
    // Resume some items if possible
    [self balanceDownloadingItems];
}

- (void)resumeDownload:(NSURL *)url {
    
    HMCDownloadItem *task = _downloadItemsDict[url];
    
    if (task == nil) {
        
        return;
    }
    
    // Update state of task
    if ([task downloadState] == HMCDownloadStatePaused) {
        
        task.downloadState = HMCDownloadStatePending;
    }
    
    // Resume item if possible
    [self balanceDownloadingItems];
}

- (void)cancelDownload:(NSURL *)url {
    
    HMCDownloadItem *task = _downloadItemsDict[url];
    
    if (task == nil) {
        
        return;
    }
    
    // Update active download counter
    if ([task downloadState] == HMCDownloadStateDownloading) {
        _activeDownloadCounter --;
    }
    
    // Cancel task
    [task cancel];
    
    // Remove task
    dispatch_async(_downloadItemManageQueue, ^{
        [_downloadItemsDict removeObjectForKey:task.url];
        [_downloadOrder removeObject:task.url];
        
    });
    
    // Resume some items if possible
    [self balanceDownloadingItems];
}

#pragma mark - Utilities

/**
 Balance number of downloading items
 */
- (void)balanceDownloadingItems {
    
    dispatch_async(_downloadItemManageQueue, ^{
        
        if (_activeDownloadCounter < _maximumDownloadItems) {
            for (NSURL *url in _downloadOrder) {
                
                HMCDownloadItem *item = _downloadItemsDict[url];
                
                if (item.downloadState == HMCDownloadStatePending) {
                    
                    BOOL isSuccess = NO;
                    if ([item receivedDataLength] > 0) {
                        item.downloadState = HMCDownloadStatePaused;
                        isSuccess = [item resume];
                    } else {
                        item.downloadState = HMCDownloadStateNotDownload;
                        isSuccess = [item start];
                    }
                    if (isSuccess) {
                        _activeDownloadCounter ++;
                        if (_activeDownloadCounter >= _maximumDownloadItems) {
                            break;
                        }
                    }
                }
            }
        }
    });
}

#pragma mark - File manager methods

/**
 Check and create directory at folder path if not existed
 */
- (void)checkAndCreateTempDirectory {
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [dirPaths objectAtIndex:0];
    _tempDir = [[NSURL fileURLWithPath:docsPath] URLByAppendingPathComponent:@"HMCDownloadManager_downloading"];
    
    [NSFileManager createDirectory:_tempDir];
    
    NSLog(@"Temp dir: %@", _tempDir.path);
}

/**
 Delete old files in temp folder
 */
- (void)deleteOldFiles {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        
        // Get all files on disk
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:HMCDownloadManager.defaultDownloadDir.path error:&error];
        
#if DEBUG
        NSAssert(!error, error.debugDescription);
#endif
        
        for (NSString *file in files) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", HMCDownloadManager.defaultDownloadDir.path, file];
            
            // Get modifidation date
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSDate *lastModifiedDate = [attributes fileModificationDate];
            
            // Skip if last modified date is in threshold
            NSDate *today = [NSDate date];
            if ([NSDate daysBetweenDate:lastModifiedDate andDate:today] <= EXPIRATION_DAYS) {
                continue;
            }
            
            // Delete file
            error = [NSFileManager removeFileAt:[NSURL URLWithString:path]];
            
        }
    });
}

@end


