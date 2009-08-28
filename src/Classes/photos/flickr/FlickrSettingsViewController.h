//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrCredentials.h"

@protocol FlickrSettingsViewControllerDelegate

- (void)deleteServiceWithCredentials:(FlickrCredentials *)credentials;
- (void)userWantsToSelectTags:(FlickrCredentials *)credentials;

@end

@interface FlickrSettingsViewController :
    UITableViewController <UIActionSheetDelegate>
{
    id<FlickrSettingsViewControllerDelegate> delegate;

    FlickrCredentials * credentials;
}

@property (nonatomic, assign) id<FlickrSettingsViewControllerDelegate> delegate;
@property (nonatomic, retain) FlickrCredentials * credentials;

- (id)initWithDelegate:(id<FlickrSettingsViewControllerDelegate>)aDelegate;

@end
