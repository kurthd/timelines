//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterCredentials+PhotoServiceAdditions.h"
#import "AccountSettings.h"

@implementation TwitterCredentials (PhotoServiceAdditions)

- (PhotoServiceCredentials *)defaultPhotoServiceCredentials
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:self.username];
    NSString * selectedService = [settings photoServiceName];

    for (PhotoServiceCredentials * c in self.photoServiceCredentials)
        if ([[c serviceName] isEqualToString:selectedService])
            return c;

    return nil;
}

@end
