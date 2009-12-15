//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DateDescription.h"

@implementation DateDescription

@synthesize dateString, timeString, amPmString;

- (void)dealloc
{
    [dateString release];
    [timeString release];
    [amPmString release];
    [super dealloc];
}

- (id)initWithDateString:(NSString *)aDateString
    timeString:(NSString *)aTimeString amPmString:(NSString *)anAmPmString
{
    if (self = [super init]) {
        dateString = [aDateString copy];
        timeString = [aTimeString copy];
        amPmString = [anAmPmString copy];
    }

    return self;
}

- (BOOL)isEqual:(id)other
{
    DateDescription * otherDesc = (DateDescription *)other;

    return [self.dateString isEqualToString:otherDesc.dateString] &&
        [self.timeString isEqualToString:otherDesc.timeString] &&
        [self.amPmString isEqualToString:otherDesc.amPmString];
}

@end
