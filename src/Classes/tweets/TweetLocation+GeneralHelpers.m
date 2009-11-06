//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetLocation+GeneralHelpers.h"

@implementation TweetLocation (GeneralHelpers)

- (CLLocation *)asCllocation
{
    // consider caching these if we end up crating too often
    double latitude = [self.latitude doubleValue];
    double longitude = [self.longitude doubleValue];
    return [[[CLLocation alloc]
        initWithLatitude:latitude longitude:longitude] autorelease];
}

@end