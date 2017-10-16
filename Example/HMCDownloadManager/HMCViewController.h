//
//  HMCViewController.m
//  HMCDownloadManager
//
//  Created by chuonghuynh on 10/16/2017.
//  Copyright (c) 2017 Chương M. Huỳnh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HMCDownloadManager/HMCDownloadManager.h>
#import "NIMutableTableViewModel.h"
#import "HMCImageDownloaderCell.h"

@interface HMCViewController : UIViewController<NITableViewModelDelegate, HMCImageDownloaderCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadAllButton;

@end


