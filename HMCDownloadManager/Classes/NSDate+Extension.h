//
//  NSDate+Extension.h
//  HMCImageCache
//
//  Created by chuonghuynh on 8/3/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 Extension for NSDate
 */
@interface NSDate(Compare)

/**
 Get number of days between 2 days

 @param fromDateTime - older date
 @param toDateTime - newer date
 @return number of days between 2 dates
 */
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

@end
