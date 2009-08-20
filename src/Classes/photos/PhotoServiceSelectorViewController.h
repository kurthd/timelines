//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoServiceSelectorViewControllerDelegate

- (NSDictionary *)photoServices;

- (void)userSelectedServiceNamed:(NSString *)serviceName;
- (void)userDidCancel;

@end

@interface PhotoServiceSelectorViewController : UITableViewController
{
    id<PhotoServiceSelectorViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * cancelButton;

    NSArray * names;
    NSArray * logos;

    BOOL allowCancel;
}

@property (nonatomic, assign) id<PhotoServiceSelectorViewControllerDelegate>
    delegate;

@property (nonatomic, assign) BOOL allowCancel;

- (IBAction)userDidCancel:(id)sender;

@end
