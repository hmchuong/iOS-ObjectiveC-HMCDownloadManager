//
//  HMCViewController.m
//  HMCDownloadManager
//
//  Created by chuonghuynh on 10/16/2017.
//  Copyright (c) 2017 Chương M. Huỳnh. All rights reserved.
//

#import "HMCViewController.h"
#import "HMCImageDownloaderCell.h"
#import "NSFileManager+Extension.h"

@interface HMCViewController ()

@property (strong, nonatomic) NSArray *cellObjects;                     // data: <CellObject>
@property (strong, nonatomic) HMCDownloadManager *downloadManager;      // Manager for download tasks
@property (strong, nonatomic) NITableViewModel *tableViewModel;         // Table view model
@property (nonatomic) dispatch_queue_t downloadQueue;                   // Queue for downloading callback
@property int downloadedCounter;                                        // Counter for downloaded items
@property (strong, nonatomic) NSURL *destinationDir;
@end

@implementation HMCViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _downloadManager = [HMCDownloadManager sharedBackgroundManager];
    _downloadQueue = dispatch_queue_create("Image Downloader", DISPATCH_QUEUE_SERIAL);
    _downloadedCounter = 0;
    
    // Build data model
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"urls" ofType:@"plist"];
    NSDictionary *nameURLDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Build URL dictionary
    NSMutableArray *dict = [[NSMutableArray alloc] init];
    
    for (NSString *key in [nameURLDict allKeys]) {
        
        HMCImageDownloaderCellObject *cellObject = [[HMCImageDownloaderCellObject alloc] initWithName:key
                                                                                                  url:[NSURL URLWithString:nameURLDict[key]]
                                                                                             delegate:self];
        CFUUIDRef udid = CFUUIDCreate(NULL);
        NSString *udidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, udid));
        cellObject.downloadTaskId = [NSFileManager _sanitizeFileNameString:udidString];
        [dataArray addObject:cellObject];
        [dict addObject:cellObject];
    }
    
    _tableViewModel = [[NITableViewModel alloc] initWithListArray:dataArray delegate:self];
    self.tableView.dataSource = _tableViewModel;
    _cellObjects = dict;
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [dirPaths objectAtIndex:0];
    _destinationDir = [NSURL fileURLWithPath:docsPath];
}

#pragma mark - HMCImageDownloaderCellDelegate

- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell startDownload:(NSURL *)url {
    
    [_downloadManager startDownloadFromURL:url
                             progressBlock:^(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
                                 
                                 // Update UI of cell
                                 CGFloat percentDone = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
                                 
                                 // Notify cell object
                                 [cell.data updateProgressPercentage:percentDone totalBytes:totalBytesExpectedToWrite];
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [cell shouldUpdateCellWithObject:cell.data];
                                 });
                                 
                             } destination:^NSURL *(NSURL *sourceUrl, NSString *identifier) {
                                 return [_destinationDir URLByAppendingPathComponent:cell.data.downloadTaskId];
                             } finishBlock:^(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error) {
                                 
                                 // Handle error
                                 if (error) {
                                     switch ([error code]) {
                                         case NSURLErrorCancelled:
                                             break;
                                         case NSURLErrorNotConnectedToInternet:
                                             [self showConnectInternetAlert];
                                             break;
                                         case NSURLErrorTimedOut:
                                             [self showConnectionTimedOut:sourceUrl];
                                             break;
                                         default:
                                             [self showErrorAlert:error.domain message:error.localizedDescription];
                                             break;
                                     }
                                     fileLocation = nil;
                                 }
                                 
                                 // No error
                                 // Update downloaded counter
                                 self.downloadedCounter ++;
                                 
                                 // Notify cell object finish downloading
                                 [cell.data finishDownloadWithFile:fileLocation];
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                     // Disable download all button if all items are downloaded
                                     if (self.downloadedCounter == [self.cellObjects count]) {
                                         [self.downloadAllButton setEnabled:NO];
                                     }
                                     
                                     [cell shouldUpdateCellWithObject:cell.data];
                                 });
                             } queue:_downloadQueue];
}

- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell pauseDownload:(NSURL *)url {
    
    [_downloadManager pauseDownload:url];
}

- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell resumeDownload:(NSURL *)url {
    
    [_downloadManager resumeDownload:url];
}

- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell cancelDownload:(NSURL *)url {
    
    [_downloadManager cancelDownload:url];
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel
                   cellForTableView:(UITableView *)tableView
                        atIndexPath:(NSIndexPath *)indexPath
                         withObject:(id)object {
    
    return [NICellFactory tableViewModel:tableViewModel
                        cellForTableView:tableView
                             atIndexPath:indexPath
                              withObject:object];
}

#pragma mark - IBActions

- (IBAction)downloadAllTapped:(UIBarButtonItem *)sender {
    
    NSDictionary *activeDownloadItems = [_downloadManager activeDownloaders];
    
    // For each url
    for (HMCImageDownloaderCellObject *cellObject in _cellObjects) {
        
        NSArray *keys = [activeDownloadItems allKeysForObject:cellObject.url];
        
        if ([keys count] > 0) {         // Check url is downloading -> Resume
            
            [_downloadManager resumeDownload:[keys firstObject]];
        } else {                        // Start download from URL
            
            if ([cellObject.progressInfo isEqualToString:FINISH]) {
                continue;
            }
            NSIndexPath *indexPath = [_tableViewModel indexPathForObject:cellObject];
            HMCImageDownloaderCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
            
            [cellObject startDownloading];
            [self imageDownloaderCell:cell startDownload:cellObject.url];
        }
    }
    
    // Disable button
    //[sender setEnabled:NO];
}

#pragma mark - Utilities

/**
 Show alert connect the internet
 */
- (void)showConnectInternetAlert {
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Connect the internet"
                                                                  message:@"This application request to connect the internet to download files"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Connect"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
                                                      }];
    
    [alert addAction:yesButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

/**
 Show connection timed out alert
 
 @param url - URL of connection timed out
 */
- (void)showConnectionTimedOut:(NSURL *)url {
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Cannot download file"
                                                                  message:[NSString stringWithFormat:@"Time out when downloading from URL: %@",[url absoluteString]]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil];
    
    [alert addAction:yesButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

/**
 Show error alert
 
 @param title title of alert
 @param message error description
 */
- (void)showErrorAlert:(NSString *)title
               message:(NSString *)message {
    
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil];
    
    [alert addAction:yesButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
