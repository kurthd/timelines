//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterCredentials.h"

@protocol PhotoServicesViewControllerDelegate
@end

@interface PhotoServicesViewController : UITableViewController
{
    id<PhotoServicesViewControllerDelegate> delegate;

    TwitterCredentials * credentials;
}

@property (nonatomic, retain) TwitterCredentials * credentials;

@property (nonatomic, assign) id<PhotoServicesViewControllerDelegate> delegate;

@end
