//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIApplication+ConfigurationAdditions.h"

@implementation UIApplication (ConfigurationAdditions)

- (BOOL)isLiteVersion
{

#if defined (HOB_TWITBIT_LITE_VERSION)

    return YES;

#else

    return NO;

#endif

}

@end
