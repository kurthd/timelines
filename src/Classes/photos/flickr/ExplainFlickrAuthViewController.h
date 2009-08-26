//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExplainFlickrAuthViewControllerDelegate <NSObject>

- (void)beginAuthorization;
- (void)userDidCancelExplanation;

@end

@interface ExplainFlickrAuthViewController : UITableViewController
{
    id<ExplainFlickrAuthViewControllerDelegate> delegate;

    UITableViewCell * activeCell;
    IBOutlet UITableViewCell * buttonCell;
    IBOutlet UITableViewCell * activityCell;
    IBOutlet UITableViewCell * authorizingCell;

    IBOutlet UIBarButtonItem * cancelButton;
}

@property (nonatomic, assign) id<ExplainFlickrAuthViewControllerDelegate>
    delegate;

- (id)initWithDelegate:(id<ExplainFlickrAuthViewControllerDelegate>)aDelegate;

- (void)showButtonView;
- (void)showActivityView;
- (void)showAuthorizingView;

#pragma mark Button actions

- (IBAction)userDidCancel;

@end
