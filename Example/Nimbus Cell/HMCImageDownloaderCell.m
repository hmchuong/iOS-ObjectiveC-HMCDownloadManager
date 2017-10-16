//
//  HMCImageDownloaderCell.m
//  MultipleDownload
//
//  Created by chuonghuynh on 8/22/17.
//  Copyright © 2017 Chương M. Huỳnh . All rights reserved.
//

@import ImageIO;
#import "HMCImageDownloaderCell.h"
#import "HMCImageCache.h"

#define PROGRESS_INFO @"%.2f %% of %.1f MB"
#define NO_IMAGE_NAME @"no_image"

@implementation HMCImageDownloaderCellObject

- (instancetype)initWithName:(NSString *)name
                         url:(NSURL *)url
                    delegate:(id<HMCImageDownloaderCellDelegate>)delegate {
    
    self = [super init];
    
    _name = name;
    _url = url;
    _delegate = delegate;
    _downloadState = HMCDownloadStateNotDownload;
    _progressInfo = NOT_DOWNLOAD;
    _image = NO_IMAGE_NAME;
    
    // Save default image to cache
    UIImage *image = [HMCImageCache.sharedInstance imageFromKey:NO_IMAGE_NAME storeToMem:YES];
    if (image == nil) {
        image = [UIImage imageNamed:NO_IMAGE_NAME];
        [HMCImageCache.sharedInstance storeImage:image withKey:NO_IMAGE_NAME];
    }
    
    return self;
}

- (UINib *)cellNib {
    
    return [UINib nibWithNibName:NSStringFromClass([HMCImageDownloaderCell class]) bundle:[NSBundle mainBundle]];
}

- (void)startDownloading {
    
    _downloadState = HMCDownloadStateDownloading;
    _progressInfo = DOWNLOADING;
    _percentDone = 0;
}

- (void)finishDownloadWithFile:(NSURL *)file {
    
    if (file == nil) {              // Error download state
        
        self.percentDone = 1;
        self.progressInfo = ERROR;
        self.downloadState = HMCDownloadStateNotDownload;
        return;
    } else {                        // Done download state
        
        self.percentDone = 0;
        self.progressInfo = FINISH;
        self.downloadState = HMCDownloadStateNotDownload;
    }
    
    // Load image from file
    UIImage *image;
    @try {
        
        image = [self resizeImageAtPath:file maxSize:200];
    } @catch (NSException *exception) {         // Error download state when cannot load image
        
        NSLog(@"Cannot load image");
        self.percentDone = 1;
        self.progressInfo = ERROR;
        self.downloadState = HMCDownloadStateNotDownload;
    }
    
    if (image != nil) {                         // Save image to cache
        
        self.image = [[file path] lastPathComponent];                               // Get key of image
        UIImage *storedImage = [self makeRoundedImage:image radius:20];
        [HMCImageCache.sharedInstance storeImage:storedImage withKey:self.image];
    }
}

- (void)updateProgressPercentage:(CGFloat)percent totalBytes:(int64_t)bytes {
    
    double totalMB = (double)bytes/(double)(1024*1024);             // total size of file in MB
    self.percentDone = percent;
    self.progressInfo = [NSString stringWithFormat:PROGRESS_INFO,percent*100,totalMB];
    self.downloadState = HMCDownloadStateDownloading;
}


#pragma mark - Utilities

/**
 Make rounded image

 @param image image to be rounded
 @param radius radius of corner
 @return rounded image
 */
-(UIImage *)makeRoundedImage:(UIImage *) image
                      radius: (float) radius {
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    imageLayer.contents = (id) image.CGImage;
    
    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = radius;
    
    UIGraphicsBeginImageContext(image.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}

/**
 Load image from file and resize it

 @param imagePath path of image file
 @param maxSize max size of image (any dimension)
 @return image after loaded
 */
- (UIImage *)resizeImageAtPath:(NSURL *)imagePath maxSize:(CGFloat)maxSize {
    
    // Create the image source
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef) imagePath, NULL);
    
    // Create thumbnail options
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(maxSize)
                                                           };
    
    // Generate the thumbnail
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
    CFRelease(src);
    
    // Write the thumbnail at path
    UIImage *image = [UIImage imageWithCGImage:thumbnail];
    
    return image;
}

@end

@interface HMCImageDownloaderCell()

@property (nonatomic) BOOL isDrawBackground;

@end

@implementation HMCImageDownloaderCell

#pragma mark - Life cycles

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    // Download information
    [_progress setHidden:YES];
    [_cancel setEnabled:NO];
    [_info setText:NOT_DOWNLOAD];
    
    // Rounded image view
    _image.layer.cornerRadius = 5;
    _image.clipsToBounds = YES;
    
    // Cancel button
    [_cancel setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
    [_cancel setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateDisabled];
    [_cancel setBackgroundImage:[self imageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    _cancel.layer.cornerRadius = 5;
    _cancel.clipsToBounds = YES;
    
    // Start-Resume-Pause button
    [_startResumePause setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
    [_startResumePause setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateDisabled];
    [_startResumePause setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:3.0/255
                                                                               green:169.0/255
                                                                                blue:244.0/255
                                                                               alpha:1]]
                                 forState:UIControlStateNormal];
    _startResumePause.layer.cornerRadius = 5;
    _startResumePause.clipsToBounds = YES;
    _isDrawBackground = NO;
    
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    // Make cell like card view in android
    if (!_isDrawBackground) {
        self.contentView.backgroundColor = [UIColor clearColor];
        UIView *whiteRoundedView = [[UIView alloc] initWithFrame:CGRectMake(10, 8, self.self.frame.size.width - 20, 135)];
        CGFloat components[] = {1.0, 1.0, 1.0, 0.9};
        whiteRoundedView.layer.backgroundColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
        whiteRoundedView.layer.masksToBounds = NO;
        whiteRoundedView.layer.cornerRadius = 2.0;
        whiteRoundedView.layer.shadowOffset = CGSizeMake(-1,1);
        whiteRoundedView.layer.shadowOpacity = 0.2;
        
        [self.contentView addSubview:whiteRoundedView];
        [self.contentView sendSubviewToBack:whiteRoundedView];
        
        _isDrawBackground = YES;
    }
}

/**
 Image with color

 @param color color to make image
 @return image of color
 */
- (UIImage *)imageWithColor:(UIColor *)color {
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Update UI

/**
 Setup downloading state
 */
- (void)setupDownloading {
    
    [_progress setHidden:NO];
    [_cancel setEnabled:YES];
    [_startResumePause setEnabled:YES];
    [_progress setProgress:[_data percentDone]];
    [_info setText:[_data progressInfo]];
    [_startResumePause setTitle:PAUSE forState:UIControlStateNormal];
}

/**
 Set up pausing state
 */
- (void)setupPausing {
    
    [_progress setHidden:NO];
    [_cancel setEnabled:YES];
    [_startResumePause setEnabled:YES];
    [_progress setProgress:[_data percentDone]];
    [_info setText:PAUSING];
    [_startResumePause setTitle:RESUME forState:UIControlStateNormal];
    
}

/**
 Set up error state
 */
- (void)setupError {
    
    [_progress setHidden:YES];
    [_cancel setEnabled:NO];
    [_startResumePause setEnabled:YES];
    [_progress setProgress:0];
    [_info setText:ERROR];
    [_startResumePause setTitle:RETRY forState:UIControlStateNormal];
}

/**
 Set up finish state
 */
- (void)setupFinish {
    
    [_progress setHidden:YES];
    [_cancel setEnabled:NO];
    [_startResumePause setEnabled:NO];
    [_progress setProgress:1];
    [_info setText:FINISH];
}

/**
 Set up not downloading state
 */
- (void)setupNotDownloading {
    
    [_progress setHidden:YES];
    [_cancel setEnabled:NO];
    [_startResumePause setEnabled:YES];
    [_progress setProgress:0];
    [_info setText:NOT_DOWNLOAD];
    [_startResumePause setTitle:START forState:UIControlStateNormal];
}

#pragma mark - NICell protocol

- (BOOL)shouldUpdateCellWithObject:(HMCImageDownloaderCellObject *)object {
    
    _data = object;
    [_name setText:[_data name]];
    
    switch (_data.downloadState) {
        case HMCDownloadStateDownloading:      // Downloading state
            [self setupDownloading];
            break;
            
        case HMCDownloadStatePaused:          // Pause downloading
            [self setupPausing];
            break;
            
        case HMCDownloadStateNotDownload:      // Not downloading
            if ([_data.progressInfo isEqualToString:ERROR]) {           // Error when downloading
                [self setupError];
            } else if ([_data.progressInfo isEqualToString:FINISH]) {   // Finish downloading
                [self setupFinish];
            } else {
                [self setupNotDownloading];                             // Not downloading
            }
            break;
            
        default:
            break;
    }
     
    // Load image from cache
    UIImage *thumbnail = [HMCImageCache.sharedInstance imageFromKey:_data.image storeToMem:YES];
    [_image setImage:thumbnail];
    
    return NO;
}


#pragma mark - IBActions

- (IBAction)startPauseResumeTapped:(UIButton *)sender {
    
    if ([sender.titleLabel.text isEqualToString:START] || [sender.titleLabel.text isEqualToString:RETRY]) {               // Start
        
        // Update UI
        _data.downloadState = HMCDownloadStateDownloading;
        _data.progressInfo = DOWNLOADING;
        _data.percentDone = 0;
        [self setupDownloading];
        
        // Send back to delegate
        if (_data != nil && [_data delegate] != nil && [_data.delegate respondsToSelector:@selector(imageDownloaderCell:startDownload:)]) {
            
            [_data.delegate imageDownloaderCell:self startDownload:[_data url]];
        }
        
    } else if ([sender.titleLabel.text isEqualToString:PAUSE]) {        // Pause
        
        // Update UI
        _data.downloadState = HMCDownloadStatePaused;
        _data.progressInfo = PAUSING;
        [self setupPausing];
        
        // Send back to delegate
        if (_data != nil && [_data delegate] != nil && [_data.delegate respondsToSelector:@selector(imageDownloaderCell:pauseDownload:)]) {
            
            [_data.delegate imageDownloaderCell:self pauseDownload:_data.url];
        }
    } else {                                                            // Resume
        
        // Update UI
        _data.downloadState = HMCDownloadStateDownloading;
        _data.progressInfo = RESUMING;
        [self setupDownloading];
        
        // Send back to delegate
        if (_data != nil && [_data delegate] != nil && [_data.delegate respondsToSelector:@selector(imageDownloaderCell:resumeDownload:)]) {
            
            [_data.delegate imageDownloaderCell:self resumeDownload:_data.url];
        }

    }
}

- (IBAction)cancelTapped:(id)sender {
    
    if (_data != nil && [_data delegate] != nil && [_data.delegate respondsToSelector:@selector(imageDownloaderCell:cancelDownload:)]) {
        
        // Update UI
        _data.downloadState = HMCDownloadStateNotDownload;
        _data.progressInfo = NOT_DOWNLOAD;
        [self setupNotDownloading];
        
        // Send back to delegate
        [_data.delegate imageDownloaderCell:self cancelDownload:_data.url];
    }
}

@end
