//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ComposeTweetViewControllerDelegate;

@interface ComposeTweetViewController :
    UIViewController <UIActionSheetDelegate, UITextFieldDelegate>
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * titleLabel;
    IBOutlet UILabel * accountLabel;

    IBOutlet UITextView * textView;

    IBOutlet UIToolbar * toolbar;
    UIBarButtonItem * sendButton;
    UIBarButtonItem * cancelButton;

    IBOutlet UILabel * characterCount;

    IBOutlet UIView * recipientView;
    IBOutlet UITextField * recipientTextField;

    BOOL displayingActivity;
    IBOutlet UIView * activityView;
    IBOutlet UIProgressView * activityProgressView;
    UIButton * activityCancelButton;

    BOOL hideRecipientView;
    NSString * currentSender;
    NSString * textViewText;
    NSString * currentRecipient;

    BOOL viewNeedsInitialization;
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

- (void)setRecipient:(NSString *)recipient;

- (void)addTextToMessage:(NSString *)text;

- (void)displayActivityView;
- (void)updateActivityProgress:(CGFloat)uploadProgress;
- (void)hideActivityView;

- (IBAction)userDidSend;
- (IBAction)userDidClose;
- (IBAction)chooseDirectMessageRecipient;
- (IBAction)promptToClearTweet;
- (IBAction)choosePhoto;
- (IBAction)choosePerson;
- (IBAction)userDidCancelActivity;

@end


@protocol ComposeTweetViewControllerDelegate

- (void)userWantsToSendTweet:(NSString *)text;
- (void)userWantsToSendDirectMessage:(NSString *)text
                         toRecipient:(NSString *)recipient;

- (void)userDidSaveTweetDraft:(NSString *)text;
- (void)userDidSaveDirectMessageDraft:(NSString *)text
                          toRecipient:(NSString *)recipient;

- (void)userWantsToSelectDirectMessageRecipient;

- (void)userWantsToSelectPhoto;
- (void)userWantsToSelectPerson;

- (void)userDidCancelActivity;

- (BOOL)clearCurrentDirectMessageDraftTo:(NSString *)recipient;
- (BOOL)clearCurrentTweetDraft;

- (void)closeView;

@end
