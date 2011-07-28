//
//  NSCalendar+CWAdditions.h
//  Mobilbank
//
//  Created by Fredrik Olsson on 2011-07-27.
//  Copyright 2011 Svenska Handelsbanken AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSCalendar (CWAdditions)

-(NSInteger)calendarUnit:(NSCalendarUnit)unit fromDate:(NSDate*)date;

-(NSDate*)truncateDate:(NSDate*)date toCalendarUnit:(NSCalendarUnit)unit;

-(NSComparisonResult)compareDate:(NSDate*)dateA toDate:(NSDate*)dateB withCalendarUnitPrecision:(NSCalendarUnit)unit;

@end
