//
//  NSCalendar+CWAdditions.m
//  Mobilbank
//
//  Created by Fredrik Olsson on 2011-07-27.
//  Copyright 2011 Svenska Handelsbanken AB. All rights reserved.
//

#import "NSCalendar+CWAdditions.h"


@implementation NSCalendar (CWAdditions)

-(NSInteger)calendarUnit:(NSCalendarUnit)unit fromDate:(NSDate*)date;
{
    NSDateComponents* components = [self components:unit fromDate:date];
    switch (unit) {
        case NSEraCalendarUnit:     return [components era];
        case NSYearCalendarUnit:    return [components year];
        case NSQuarterCalendarUnit: return [components quarter];
        case NSMonthCalendarUnit:   return [components month];
        case NSWeekCalendarUnit:    return [components week];
        case NSDayCalendarUnit:     return [components day];
        case NSWeekdayCalendarUnit: return [components weekday];
        case NSHourCalendarUnit:    return [components hour];
        case NSMinuteCalendarUnit:  return [components minute];
        case NSSecondCalendarUnit:  return [components second];
        default:
            return NSUndefinedDateComponent;
    }
}

-(NSInteger)truncationMaskForCalendarUnit:(NSCalendarUnit)unit;
{
    NSInteger mask = 0;
    switch (unit) {
        // Intentionall fall-through for all cases.
        case NSSecondCalendarUnit:  mask |= NSSecondCalendarUnit;
        case NSMinuteCalendarUnit:  mask |= NSMinuteCalendarUnit;
        case NSHourCalendarUnit:    mask |= NSHourCalendarUnit;
        case NSDayCalendarUnit:     mask |= NSDayCalendarUnit;
        case NSWeekdayCalendarUnit: mask |= NSWeekdayCalendarUnit;
        case NSWeekCalendarUnit:    mask |= NSWeekCalendarUnit;
        case NSMonthCalendarUnit:   mask |= NSMonthCalendarUnit;
        case NSQuarterCalendarUnit: mask |= NSQuarterCalendarUnit;
        case NSYearCalendarUnit:    mask |= NSYearCalendarUnit;
        case NSEraCalendarUnit:     mask |= NSEraCalendarUnit;
            return mask;
        default:
            return NSUndefinedDateComponent;
    }    
}

-(NSDate*)truncateDate:(NSDate*)date toCalendarUnit:(NSCalendarUnit)unit;
{
    NSInteger mask = [self truncationMaskForCalendarUnit:unit];
        NSAssert(mask != 0, @"Unsupported calendar unit for truncation %d", unit);
    NSDateComponents* components = [self components:mask fromDate:date];
    return [self dateFromComponents:components];
}

-(NSComparisonResult)compareDate:(NSDate*)dateA toDate:(NSDate*)dateB withCalendarUnitPrecision:(NSCalendarUnit)unit;
{
    dateA = [self truncateDate:dateA toCalendarUnit:unit];
    dateB = [self truncateDate:dateB toCalendarUnit:unit];
    return [dateA compare:dateB];
}

@end
