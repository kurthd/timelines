//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Trend.h"

@implementation Trend

@synthesize name, query;

- (void)dealloc
{
    self.name = nil;
    self.query = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", name, query];
}

@end