//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposeTweetViewControllerDelegate.h"

@interface ComposeTweetViewController :
    UIViewController <UIActionSheetDelegate, UITextFieldDelegate>
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UITextView * textView;

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIToolbar * toolbar;
    IBOutlet UIBarButtonItem * sendButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UILabel * characterCount;
    IBOutlet UILabel * accountLabel;

    IBOutlet UIView * recipientView;
    IBOutlet UITextField * recipientTextField;

    IBOutlet UIView * activityView;
    BOOL displayingActivity;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

- (void)composeTweet:(NSString *)text from:(NSString *)sender;
- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
           inReplyTo:(NSString *)recipient;

- (void)composeDirectMessage:(NSString *)text from:(NSString *)sender;
- (void)composeDirectMessage:(NSString *)text
                        from:(NSString *)sender
                          to:(NSString *)recipient;

- (void)addTextToMessage:(NSString *)text;

- (void)displayActivityView;
- (void)hideActivityView;

- (IBAction)userDidSave;
- (IBAction)userDidCancel;
- (IBAction)choosePhoto;

@end
