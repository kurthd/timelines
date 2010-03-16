//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoServiceSelectorViewControllerDelegate;

@interface PhotoServiceSelectorViewController : UITableViewController
{
    id<PhotoServiceSelectorViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * cancelButton;

    /*
    NSArray * names;
    NSArray * logos;
    */

    NSDictionary * freePhotoServices;
    NSDictionary * premiumPhotoServices;

    BOOL allowCancel;
}

@property (nonatomic, assign) id<PhotoServiceSelectorViewControllerDelegate>
    delegate;

@property (nonatomic, assign) BOOL allowCancel;

- (IBAction)userDidCancel:(id)sender;

@end


@protocol PhotoServiceSelectorViewControllerDelegate

- (NSDictionary *)freePhotoServices;
- (NSDictionary *)premiumPhotoServices;

- (void)userSelectedServiceNamed:(NSString *)serviceName;
- (void)userDidCancel;

@end

