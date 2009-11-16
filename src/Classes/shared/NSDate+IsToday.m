//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSDate+IsToday.h"

@implementation NSDate (IsToday)

- (BOOL)isToday
{
    static NSCalendar * calendar = nil;
    if (!calendar)
        calendar = [[NSCalendar currentCalendar] retain];

    static NSDate * startOfToday = nil;
    if (!startOfToday) {
        startOfToday = [[NSDate alloc] init];
        NSCalendarUnit units =
            NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents * components = [calendar components:units 
                                                    fromDate:startOfToday];

        [components setHour:components.hour * -1];
        [components setMinute:components.minute * -1];
        [components setSecond:components.second * -1];

        startOfToday = [[calendar dateByAddingComponents:components
                                                  toDate:startOfToday
                                                 options:0] retain];
    }

    return [self compare:startOfToday] == NSOrderedDescending;
}

- (BOOL) isYesterday
{
    NSCalendar * currentCalendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags =
        NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents * selfComps =
        [currentCalendar components:unitFlags fromDate:self];
    
    NSDate * now = [NSDate date];

    NSDateComponents * nowComps =
        [currentCalendar components:unitFlags fromDate:now];
    
    return [nowComps day] - 1 == [selfComps day] &&
        [nowComps month] == [selfComps month] &&
        [nowComps year] == [selfComps year];
}

- (BOOL) isLessThanWeekAgo
{
    NSCalendar * currentCalendar = [NSCalendar currentCalendar];

    unsigned unitFlags =
    NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents * selfComps =
        [currentCalendar components:unitFlags fromDate:self];
    
    NSDateComponents * comps = [[[NSDateComponents alloc] init] autorelease];
    [comps setDay:[selfComps day]];
    [comps setMonth:[selfComps month]];
    [comps setYear:[selfComps year]];
    
    NSDate * beginningOfToday = [currentCalendar dateFromComponents:comps];

    return -[beginningOfToday timeIntervalSinceNow] < 60 * 60 * 24 * 7;
}

@end
