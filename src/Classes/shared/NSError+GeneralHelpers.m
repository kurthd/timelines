//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSError+GeneralHelpers.h"

@implementation NSError (GeneralHelpers)

- (NSString *)detailedDescription
{
    NSMutableString * desc = [self.localizedDescription mutableCopy];
    NSArray * detailedErrors = [self.userInfo objectForKey:NSDetailedErrorsKey];

    if (detailedErrors.count)
        for (NSError * detailedError in detailedErrors)
            [desc appendFormat:@"\tDetailed error: %@", detailedError.userInfo];
    else
        [desc appendFormat:@"\t%@", self.userInfo];

    NSError * underlyingError =
        [self.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError)
        [desc appendFormat:@"\tUnderlying error: %@",
            [underlyingError detailedDescription]];

    return [desc autorelease];
}

@end