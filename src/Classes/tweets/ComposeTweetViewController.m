//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"

static const NSInteger MAX_TWEET_LENGTH = 140;

@interface ComposeTweetViewController ()

- (void)disableForm;
- (void)enableForm;
- (void)showRecipientView;
- (void)hideRecipientView;

- (void)enableSendButtonFromInterface;
- (void)enableSendButtonFromText:(NSString *)text
                    andRecipient:(NSString *)recipient;

- (void)updateCharacterCountFromInterface;
- (void)updateCharacterCountFromText:(NSString *)text;

@end

@implementation ComposeTweetViewController

@synthesize delegate;

- (void)dealloc
{
    [textView release];

    [navigationBar release];
    [toolbar release];
    [sendButton release];
    [cancelButton release];

    [characterCount release];
    [accountLabel release];

    [recipientView release];
    [recipientTextField release];

    [activityView release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    displayingActivity = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self enableSendButtonFromInterface];
    if (!displayingActivity) {
        if (recipientTextField.text.length == 0)
            [recipientTextField becomeFirstResponder];
        else
            [textView becomeFirstResponder];
    }

    [self updateCharacterCountFromText:textView.text];

    CGRect characterCountFrame = characterCount.frame;
     // hack -- this needs to be 210 when displayed, but 133 after a rotation
    characterCountFrame.origin.y = 210;
    characterCount.frame = characterCountFrame;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [recipientTextField resignFirstResponder];
    [textView resignFirstResponder];

    textView.text = @"";
    recipientTextField.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation {

    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortrait) {

        CGRect recipientViewFrame = recipientView.frame;
        recipientViewFrame.size.height = 39;
        recipientView.frame = recipientViewFrame;

        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.y = 83;
        textView.frame = textViewFrame;

        CGRect characterCountFrame = characterCount.frame;
        characterCountFrame.origin.y = 133;
        characterCount.frame = characterCountFrame;
        characterCount.textColor = [UIColor whiteColor];
        characterCount.backgroundColor = [UIColor clearColor];

        toolbar.hidden = NO;
    } else {
        CGRect recipientViewFrame = recipientView.frame;
        recipientViewFrame.size.height = 29;
        recipientView.frame = recipientViewFrame;

        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.y = 73;
        textView.frame = textViewFrame;

        CGRect characterCountFrame = characterCount.frame;
        characterCountFrame.origin.y = 173;
        characterCount.frame = characterCountFrame;
        characterCount.textColor = [UIColor twitchGrayColor];
        characterCount.backgroundColor = [UIColor whiteColor];

        toolbar.hidden = YES;
    }

	return YES;
}

- (void)composeTweet:(NSString *)text from:(NSString *)sender
{
    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];

    [self hideRecipientView];
    [textView becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];

    navigationBar.topItem.title =
        NSLocalizedString(@"composetweet.view.title", @"");
}

- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
           inReplyTo:(NSString *)recipient
{
    textView.text = text;
    accountLabel.text = [NSString stringWithFormat:@"@%@", sender];

    [self hideRecipientView];
    [textView becomeFirstResponder];
    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:text];

    navigationBar.topItem.title =
        NSLocalizedString(@"composetweet.view.title", @"");
}

- (void)composeDirectMessage:(NSString *)text from:(NSString *)sender
{
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
    navigationBar.topItem.title = @"Direct Message";
}

- (void)addTextToMessage:(NSString *)text
{
    NSString * current = textView.text;
    textView.text = [current stringByAppendingFormat:@" %@", text];

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:textView.text];
}

- (void)displayActivityView
{
    activityView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:activityView
                             cache:YES];

    activityView.alpha = 0.75;
    [self.view addSubview:activityView];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    [UIView commitAnimations];

    [textView resignFirstResponder];
    displayingActivity = YES;
}

- (void)hideActivityView
{
    activityView.alpha = 0.75;
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
    [self enableSendButtonFromText:s andRecipient:recipientTextField.text];

    return YES;
}

#pragma mark Button actions

- (IBAction)userDidSave
{
    [self disableForm];
    [delegate userDidSave:textView.text];
}

- (IBAction)userDidCancel
{
    if (textView.text.length == 0)
        [delegate userDidCancel];
    else {
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

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:  // save as draft
            [delegate userDidSaveAsDraft:textView.text];
            break;
        case 1:  // user confirmed the cancel
            [delegate userDidCancel];
            break;
    }

    [actionSheet autorelease];
}

#pragma mark Helpers

- (void)disableForm
{
    cancelButton.enabled = NO;
    sendButton.enabled = NO;
}

- (void)enableForm
{
    sendButton.enabled = YES;
    cancelButton.enabled = YES;
}

- (void)showRecipientView
{
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
    if (!recipientView.hidden) {
        CGRect recipientFrame = recipientView.frame;
        CGRect textViewFrame = textView.frame;

        textViewFrame.origin.y = navigationBar.frame.size.height;
        textViewFrame.size.height += recipientFrame.size.height;

        textView.frame = textViewFrame;
        recipientView.hidden = YES;
    }
}

// convenience method
- (void)enableSendButtonFromInterface
{
    [self enableSendButtonFromText:textView.text
                      andRecipient:recipientTextField.text];
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

@end
