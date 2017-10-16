# HMCDownloadManager

[![Build Status](https://travis-ci.org/hmchuong/iOS-ObjectiveC-HMCDownloadManager.svg?branch=master)](https://travis-ci.org/hmchuong/iOS-ObjectiveC-HMCDownloadManager)
[![Version](https://img.shields.io/cocoapods/v/HMCDownloadManager.svg?style=flat)](http://cocoapods.org/pods/HMCDownloadManager)
[![License](https://img.shields.io/cocoapods/l/HMCDownloadManager.svg?style=flat)](http://cocoapods.org/pods/HMCDownloadManager)
[![Platform](https://img.shields.io/cocoapods/p/HMCDownloadManager.svg?style=flat)](http://cocoapods.org/pods/HMCDownloadManager)

HMCDownloadManager is a wrapper supporting downloading multiple files within a singleton object.
By download multiple files concurrently (same or not same URL), we can set **maximumDownloadItem** for number of maximum items can be downloaded concurrently. We can choose between background (items can be downloaded when app is in background) or default download manager. Callback each block for each item in different queues.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- iOS 8.0+
- Xcode 8.3+

## Features
- [x] Download multiple file within a singleton object
- [x] Support normal and background download
- [x] Copy to destination file when finish downloading
- [x] Support pause, resume, cancel downloading an item
- [x] Auto continue download file after interrupt without cancelling
- [x] Support multiple callback blocks for same url
- [x] Write/ read file only, don't use memory for store download item

## Installation

HMCDownloadManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'HMCDownloadManager'
```

## Usage

### To get default download manager
```ObjectiveC
HMCDownloadManager *defaultDownload = [HMCDownloadManager sharedDefaultManager];
```

### To get background download manager
```ObjectiveC
HMCDownloadManager *defaultDownload = [HMCDownloadManager sharedBackgroundManager];
```

### To edit maximum waiting time for the next data receiving for default manager
```ObjectiveC
defaultDownload.timeoutForRequest = 5.0;
```

### To edit

### To start download from URL

### To pause download from URL

### To resume download from URL

### To cancel download from URL

## Author

chuonghuynh, minhchuong.itus@gmail.com

## License

HMCDownloadManager is available under the MIT license. See the LICENSE file for more info.
