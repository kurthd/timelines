//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExplainOauthViewControllerDelegate

- (void)beginAuthorization;
- (void)userDidCancelExplanation;

@end

@interface ExplainOauthViewController : UIViewController
{
    id<ExplainOauthViewControllerDelegate> delegate;

    IBOutlet UITableView * tableView;

    UITableViewCell * activeCell;
    IBOutlet UITableViewCell * buttonCell;
    IBOutlet UITableViewCell * activityCell;
    IBOutlet UITableViewCell * authorizingCell;

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIBarButtonItem * cancelButton;

    BOOL allowsCancel;
}

@property (nonatomic, assign) id<ExplainOauthViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;

- (IBAction)userDidCancel;

- (void)showButtonView;
- (void)showActivityView;
- (void)showAuthorizingView;

@end
