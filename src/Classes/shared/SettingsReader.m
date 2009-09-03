//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SettingsReader.h"

@implementation SettingsReader

static BOOL alreadyReadFetchQuantityValue;
static NSInteger fetchQuantity;

+ (NSInteger)fetchQuantity
{
    if (!alreadyReadFetchQuantityValue) {
        alreadyReadFetchQuantityValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        fetchQuantity = [defaults integerForKey:@"fetch_quantity"];
        if (fetchQuantity == 0)
            fetchQuantity = [[self class] defaultFetchQuantity];
    }

    return fetchQuantity;
}

+ (NSInteger)defaultFetchQuantity
{
    return 20;
}

@end
