//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"

static const NSInteger MAX_TWEET_LENGTH = 140;

@interface UIApplication (KeyboardView)

- (UIView *)keyboardView;

@end

@implementation UIApplication (KeyboardView)

- (UIView *)keyboardView
{
    NSArray *windows = [self windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])
        for (UIView *view in [window subviews])
            if (!strcmp(object_getClassName(view), "UIKeyboard"))
                return view;
    
    return nil;
}

@end


@interface ComposeTweetViewController ()

- (void)showRecipientView;
- (void)hideRecipientView;

- (void)enableSendButtonFromInterface;
- (void)enableSendButtonFromText:(NSString *)text;
- (void)enableSendButtonFromText:(NSString *)text
                    andRecipient:(NSString *)recipient;

- (void)updateCharacterCountFromInterface;
- (void)updateCharacterCountFromText:(NSString *)text;

- (void)displayForPortraitMode;
- (void)correctCharacterCountFrameWhenDisplayed;

- (BOOL)composingDirectMessage;

@property (nonatomic, copy) NSString * currentSender;
@property (nonatomic, copy) NSString * textViewText;
@property (nonatomic, copy) NSString * currentRecipient;

@end

@implementation ComposeTweetViewController

@synthesize delegate, sendButton, cancelButton, currentSender, textViewText,
    displayingActivity, currentRecipient;

- (void)dealloc
{
    [textView release];

    [toolbar release];
    [sendButton release];
    [cancelButton release];

    [characterCount release];
    [accountLabel release];

    [recipientView release];
    [recipientTextField release];

    [activityView release];
    [activityProgressView release];
    [activityCancelButton release];

    [currentSender release];
    [textViewText release];
    [currentRecipient release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (hideRecipientView)
        [self hideRecipientView];

    if (self.currentSender)
        accountLabel.text =
            [NSString stringWithFormat:@"@%@", self.currentSender];
    if (self.textViewText)
        textView.text = self.textViewText;
    if (self.currentRecipient)
        recipientTextField.text = self.currentRecipient;

    static const NSInteger BUTTON_WIDTH = 134;
    CGRect buttonFrame =
        CGRectMake((320 - BUTTON_WIDTH) / 2, 156, BUTTON_WIDTH, 46);
    activityCancelButton =
        [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
    NSString * cancelButtonTitle =
        NSLocalizedString(@"composetweet.cancelshortening", @"");
    [activityCancelButton setTitle:cancelButtonTitle
        forState:UIControlStateNormal];
    UIImage * normalImage =
        [[UIImage imageNamed:@"CancelButton.png"]
        stretchableImageWithLeftCapWidth:13.0 topCapHeight:0.0];
    [activityCancelButton setBackgroundImage:normalImage
        forState:UIControlStateNormal];
    activityCancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [activityCancelButton setTitleColor:[UIColor whiteColor]
        forState:UIControlStateNormal];
    [activityCancelButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateHighlighted];
    [activityCancelButton setTitleShadowColor:[UIColor twitchDarkGrayColor]
        forState:UIControlStateNormal];
    activityCancelButton.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    [activityCancelButton addTarget:self action:@selector(userDidCancelActivity)
        forControlEvents:UIControlEventTouchUpInside];
    [activityView addSubview:activityCancelButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self enableSendButtonFromInterface];

    [self updateCharacterCountFromText:textView.text];

    // HACK: character count label doesn't properly display when shown from
    // landscape mode otherwise
    [self performSelector:@selector(correctCharacterCountFrameWhenDisplayed)
        withObject:nil afterDelay:0];

    if (hideRecipientView)
        [textView becomeFirstResponder];
    else
        [recipientTextField becomeFirstResponder];
}

- (void)correctCharacterCountFrameWhenDisplayed
{
    CGRect characterCountFrame = characterCount.frame;
    // hack -- this needs to be 167 when displayed, but 104 after a rotation
    characterCountFrame.origin.y = 167;
    characterCount.frame = characterCountFrame;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self displayForPortraitMode];

    [recipientTextField resignFirstResponder];
    [textView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return !displayingActivity;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    NSLog(@"Did rotate to interface orientation.");
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self displayForPortraitMode];
    else {
        if ([self composingDirectMessage]) {
            CGRect recipientViewFrame = recipientView.frame;
            recipientViewFrame.size.height = 29;
            recipientView.frame = recipientViewFrame;

            CGRect textViewFrame = textView.frame;
            textViewFrame.origin.y = 29;
            textView.frame = textViewFrame;
        }

        CGRect characterCountFrame = characterCount.frame;
        characterCountFrame.origin.y = 129;
        characterCount.frame = characterCountFrame;

        characterCount.textColor = [UIColor twitchGrayColor];
        characterCount.backgroundColor = [UIColor whiteColor];

        toolbar.hidden = YES;
        accountLabel.hidden = YES;
    }
}

- (void)displayForPortraitMode
{
    if ([self composingDirectMessage]) {
        CGRect recipientViewFrame = recipientView.frame;
        recipientViewFrame.size.height = 39;
        recipientView.frame = recipientViewFrame;

        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.y = 39;
        textView.frame = textViewFrame;
    }

    CGRect characterCountFrame = characterCount.frame;
    characterCountFrame.origin.y = 104;
    characterCount.frame = characterCountFrame;

    characterCount.textColor = [UIColor whiteColor];
    characterCount.backgroundColor = [UIColor clearColor];

    toolbar.hidden = NO;
    accountLabel.hidden = NO;
}

- (void)composeTweet:(NSString *)text from:(NSString *)sender
{
    self.currentSender = sender;
    self.textViewText = text;

    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];
    recipientTextField.text = @"";

    [self hideRecipientView];
    [textView becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];

    self.navigationItem.title =
        NSLocalizedString(@"composetweet.view.title", @"");
}

- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
           inReplyTo:(NSString *)recipient
{
    self.currentSender = sender;
    self.textViewText = text;

    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];
    recipientTextField.text = @"";

    [self hideRecipientView];
    [textView becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];

    self.navigationItem.title =
        NSLocalizedString(@"composetweet.view.title", @"");
}

- (void)composeDirectMessage:(NSString *)text from:(NSString *)sender
{
    self.currentSender = sender;
    self.textViewText = text;

    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];
    recipientTextField.text = @"";

    [self showRecipientView];
    [recipientTextField becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];
}

- (void)composeDirectMessage:(NSString *)text
                        from:(NSString *)sender
                          to:(NSString *)recipient
{
    self.currentSender = sender;
    self.textViewText = text;
    self.currentRecipient = recipient;

    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];
    recipientTextField.text = recipient;

    [self showRecipientView];
    NSLog(@"Recipient: '%@'", recipient);
    if (recipient.length)
        [textView becomeFirstResponder];
    else
        [recipientTextField becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];
    self.navigationItem.title = @"Direct Message";
}

- (void)addTextToMessage:(NSString *)text
{
    NSString * current = textView.text;
    textView.text = [current stringByAppendingFormat:@" %@", text];

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:textView.text];
}

- (void)updateActivityProgress:(CGFloat)uploadProgress
{
    if (activityProgressView.progress != uploadProgress)
        activityProgressView.progress = uploadProgress;
}

- (void)displayActivityView
{
    activityView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:activityView
                             cache:YES];

    activityView.alpha = 0.8;
    UIView * keyboardView = [[UIApplication sharedApplication] keyboardView];
    UIView * keyView = keyboardView ? [keyboardView superview] : self.view;
    [keyView addSubview:activityView];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    [UIView commitAnimations];

    displayingActivity = YES;
}

- (void)hideActivityView
{
    activityView.alpha = 0.8;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:activityView
                             cache:YES];

    activityView.alpha = 0.0;
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

    [UIView commitAnimations];

    displayingActivity = NO;
}

#pragma mark UITextFieldDelegate implementation

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self enableSendButtonFromText:textView.text andRecipient:@""];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textView becomeFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string
{
    NSString * s = [textField.text stringByReplacingCharactersInRange:range
                                                           withString:string];

    [self enableSendButtonFromText:textView.text andRecipient:s];

    return YES;
}

#pragma mark UITextViewDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return !displayingActivity;
}

- (BOOL)textView:(UITextView *)aTextView
    shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (displayingActivity)
        return NO;

    NSString * s = [textView.text stringByReplacingCharactersInRange:range
                                                          withString:text];

    [self updateCharacterCountFromText:s];

    if ([self composingDirectMessage]) {
        [self enableSendButtonFromText:s andRecipient:recipientTextField.text];
        [delegate userDidSaveDirectMessageDraft:s
                                    toRecipient:recipientTextField.text
                                    dismissView:NO];
    } else {
        [self enableSendButtonFromText:s];
        [delegate userDidSaveTweetDraft:s dismissView:NO];
    }

    return YES;
}

#pragma mark Button actions

- (IBAction)userDidSave
{
    if ([self composingDirectMessage])
        [delegate userWantsToSendDirectMessage:textView.text
                                   toRecipient:recipientTextField.text];
    else
        [delegate userWantsToSendTweet:textView.text];
}

- (IBAction)userDidCancel
{
    if (textView.text.length == 0) {
        if ([self composingDirectMessage])
            [delegate
                userDidCancelComposingDirectMessage:textView.text
                                        toRecipient:recipientTextField.text];
        else
            [delegate userDidCancelComposingTweet:textView.text];
    } else {
        NSString * cancelTitle =
            NSLocalizedString(@"composetweet.cancel.confirm.cancel", @"");
        NSString * saveTitle =
            NSLocalizedString(@"composetweet.cancel.confirm.save", @"");
        NSString * dontSaveTitle =
            NSLocalizedString(@"composetweet.cancel.confirm.dontsave", @"");

        UIActionSheet * sheet =
            [[UIActionSheet alloc] initWithTitle:nil
                                        delegate:self
                               cancelButtonTitle:cancelTitle
                          destructiveButtonTitle:nil
                               otherButtonTitles:saveTitle, dontSaveTitle, nil];

        [sheet showInView:self.view];
    }
}

- (IBAction)choosePhoto
{
    [delegate userWantsToSelectPhoto];
}

- (IBAction)userDidCancelActivity
{
    [delegate userDidCancelActivity];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:  // save as draft
            if ([self composingDirectMessage])
                [delegate userDidSaveDirectMessageDraft:textView.text
                                            toRecipient:recipientTextField.text
                                            dismissView:YES];
            else
                [delegate userDidSaveTweetDraft:textView.text dismissView:YES];
            break;
        case 1:  // user confirmed the cancel
            if ([self composingDirectMessage]) {
                NSString * recipient = recipientTextField.text;
                [delegate userDidCancelComposingDirectMessage:textView.text
                                                  toRecipient:recipient];
            } else
                [delegate userDidCancelComposingTweet:textView.text];
            break;
    }

    [actionSheet autorelease];
}

#pragma mark Helpers

- (void)showRecipientView
{
    hideRecipientView = NO;
    if (recipientView.hidden) {
        CGRect recipientFrame = recipientView.frame;
        CGRect textViewFrame = textView.frame;

        textViewFrame.origin.y += recipientFrame.size.height;
        textViewFrame.size.height -= recipientFrame.size.height;

        textView.frame = textViewFrame;
        recipientView.hidden = NO;
    }
}

- (void)hideRecipientView
{
    hideRecipientView = YES;
    if (!recipientView.hidden) {
        CGRect recipientFrame = recipientView.frame;
        CGRect textViewFrame = textView.frame;

        textViewFrame.origin.y = 0;
        textViewFrame.size.height += recipientFrame.size.height;

        textView.frame = textViewFrame;
        recipientView.hidden = YES;
    }
}

// convenience method
- (void)enableSendButtonFromInterface
{
    if ([self composingDirectMessage])
        [self enableSendButtonFromText:textView.text
                          andRecipient:recipientTextField.text];
    else
        [self enableSendButtonFromText:textView.text];
}

- (void)enableSendButtonFromText:(NSString *)text
{
    sendButton.enabled = text.length > 0 && text.length <= MAX_TWEET_LENGTH;
}

- (void)enableSendButtonFromText:(NSString *)text
                    andRecipient:(NSString *)recipient
{
    sendButton.enabled =
        recipient.length > 0 &&
        (text.length > 0 && text.length <= MAX_TWEET_LENGTH);
}

// convenience method
- (void)updateCharacterCountFromInterface
{
    [self updateCharacterCountFromText:textView.text];
}

- (void)updateCharacterCountFromText:(NSString *)text
{
    characterCount.text =
        [NSString stringWithFormat:@"%d", MAX_TWEET_LENGTH - text.length];

}

- (BOOL)composingDirectMessage
{
    return recipientView.hidden == NO;
}

@end
