//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterCredentials.h"

@protocol PhotoServicesViewControllerDelegate

- (NSArray *)servicesForAccount:(TwitterCredentials *)credentials;
- (void)userWantsToAddNewPhotoService:(TwitterCredentials *)credentials;

@end

@interface PhotoServicesViewController : UITableViewController
{
    id<PhotoServicesViewControllerDelegate> delegate;

    TwitterCredentials * credentials;
    NSArray * services;
}

@property (nonatomic, assign) id<PhotoServicesViewControllerDelegate> delegate;
@property (nonatomic, retain) TwitterCredentials * credentials;

@end
