//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MKPlacemark+GeneralHelpers.h"

@implementation MKPlacemark (GeneralHelpers)

- (NSString *)humanReadableDescription
{
    NSString * primary, * secondary, * tertiary;

    if ([self thoroughfare]) {
        primary = [self thoroughfare];
        secondary = [self subLocality] ? [self subLocality] : [self locality];
        tertiary =
            [self subLocality] ? [self locality] : [self administrativeArea];
    } else if ([self subLocality]) {
        primary = [self subLocality];
        secondary = [self locality];
        tertiary = [self administrativeArea];
    } else if ([self locality]) {
        primary = [self locality];
        secondary = [self administrativeArea];
        tertiary = [self country];
    } else if ([self administrativeArea]) {
        primary = [self administrativeArea];
        secondary = [self country];
        tertiary = nil;
    } else if ([self country]) {
        primary = [self country];
        secondary = nil;
        tertiary = nil;
    }

    NSMutableString * desc = [NSMutableString string];
    if (primary)
        [desc appendString:primary];
    if (secondary)
        [desc appendFormat:@", %@", secondary];
    if (tertiary)
        [desc appendFormat:@", %@", tertiary];

    return desc;
}

@end
