//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterCredentials+PhotoServiceAdditions.h"
#import "AccountSettings.h"

@implementation TwitterCredentials (PhotoServiceAdditions)

- (PhotoServiceCredentials *)defaultServiceCredentials:(SEL)type
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:self.username];
    NSString * selectedService = [settings performSelector:type];

    for (PhotoServiceCredentials * c in self.photoServiceCredentials)
        if ([[c serviceName] isEqualToString:selectedService])
            return c;

    return nil;
}

- (PhotoServiceCredentials *)defaultPhotoServiceCredentials
{
    return [self defaultServiceCredentials:@selector(photoServiceName)];
}

- (PhotoServiceCredentials *)defaultVideoServiceCredentials
{
    return [self defaultServiceCredentials:@selector(videoServiceName)];
}

@end
