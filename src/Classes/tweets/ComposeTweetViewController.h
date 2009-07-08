//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposeTweetViewControllerDelegate.h"

@interface ComposeTweetViewController : UIViewController <UIActionSheetDelegate>
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UITextView * textView;

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIBarButtonItem * sendButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UILabel * characterCount;
    IBOutlet UILabel * accountLabel;

    IBOutlet UIView * activityView;
    BOOL displayingActivity;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

- (void)setTitle:(NSString *)title;
- (void)setUsername:(NSString *)username;
- (void)promptWithText:(NSString *)text;
- (void)addTextToMessage:(NSString *)text;

- (void)displayActivityView;
- (void)hideActivityView;

- (IBAction)userDidSave;
- (IBAction)userDidCancel;
- (IBAction)choosePhoto;

@end
