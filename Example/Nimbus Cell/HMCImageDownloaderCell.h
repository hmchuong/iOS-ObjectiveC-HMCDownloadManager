//
//  HMCImageDownloaderCell.h
//  MultipleDownload
//
//  Created by chuonghuynh on 8/22/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NICellFactory.h"
#import "HMCDownloadManager.h"

#define NOT_DOWNLOAD @"Not download"
#define DOWNLOADING @"Downloading"
#define FINISH @"Finish"
#define ERROR @"Error, retry"
#define PAUSING @"Paused"
#define RESUMING @"Resuming"

#define RETRY @"Retry"
#define START @"Start"
#define PAUSE @"Pause"
#define RESUME @"Resume"

@class HMCImageDownloaderCell;

/**
 Delegate of imageDownloaderCell
 */
@protocol HMCImageDownloaderCellDelegate <NSObject>

@required

/**
 Start download from URL

 @param cell - cell inform
 @param url - url to download
 */
- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell
              startDownload:(NSURL *)url;

/**
 Pause download from URL

 @param cell - cell inform
 */
- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell
              pauseDownload:(NSURL *)url;

/**
 Resume download from URL

 @param cell - cell inform
 @param url - url to resume
 */
- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell
             resumeDownload:(NSURL *)url;

/**
 Cancel download from URL

 @param cell - cell inform
 @param url - url to cancel
 */
- (void)imageDownloaderCell:(HMCImageDownloaderCell *)cell
             cancelDownload:(NSURL *)url;

@end



/**
 Data object for download cell
 */
@interface HMCImageDownloaderCellObject : NSObject<NINibCellObject>

#pragma mark - Properties

@property (strong, nonatomic) NSString *name;                           // Name of object
@property (strong, nonatomic) NSURL *url;                               // URL of object
@property (weak, nonatomic) id<HMCImageDownloaderCellDelegate> delegate;   // delegate to callback

@property (strong, nonatomic) NSString *progressInfo;                   // Progress info
@property CGFloat percentDone;                                          // Percentage to done download
@property HMCDownloadState downloadState;                               // Download state
@property NSString *image;                                              // Image key after download

@property (strong, nonatomic) NSString *downloadTaskId;                 // Download task id

#pragma mark - Methods

/**
 Init with name, url and delegate

 @param name name of download item
 @param url url of download item
 @param delegate delegate to callback when user interacts with cell
 @return HMCImageDownloaderCellObject after init
 */
- (instancetype)initWithName:(NSString *)name
                         url:(NSURL *)url
                    delegate:(id<HMCImageDownloaderCellDelegate>)delegate;

- (void)startDownloading;

/**
 Set up downloaded image when finish download

 @param file downloaded file path
 */
- (void)finishDownloadWithFile:(NSURL *)file;

/**
 Update information when downloading
 
 @param percent - percentage of downloading
 @param bytes - total bytes of file
 */
- (void)updateProgressPercentage:(CGFloat)percent totalBytes:(int64_t)bytes;

@end


/**
 Download table cell
 */
@interface HMCImageDownloaderCell : UITableViewCell<NICell>

@property (weak, nonatomic) IBOutlet UIImageView *image;                // Image to show
@property (weak, nonatomic) IBOutlet UILabel *name;                     // Name of object
@property (weak, nonatomic) IBOutlet UIProgressView *progress;          // Progress bar
@property (weak, nonatomic) IBOutlet UILabel *info;                     // info when downloading
@property (weak, nonatomic) IBOutlet UIButton *startResumePause;        // Start - Resume - Pause button
@property (weak, nonatomic) IBOutlet UIButton *cancel;                  // Cancel button

@property (strong, nonatomic) HMCImageDownloaderCellObject *data;          // data object

@end
