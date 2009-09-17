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

    IBOutlet UIToolbar * toolbar;
    UIBarButtonItem * sendButton;
    UIBarButtonItem * cancelButton;

    IBOutlet UILabel * characterCount;
    IBOutlet UILabel * accountLabel;

    IBOutlet UIView * recipientView;
    IBOutlet UITextField * recipientTextField;

    IBOutlet UIView * activityView;
    BOOL displayingActivity;
    
    BOOL hideRecipientView;
    NSString * currentSender;
    NSString * textViewText;
    NSString * currentRecipient;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

@property (nonatomic, retain) UIBarButtonItem * sendButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, assign) BOOL displayingActivity;

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
- (IBAction)userDidCancelActivity;

@end
