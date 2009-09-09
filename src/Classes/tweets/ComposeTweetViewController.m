//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"

static const NSInteger MAX_TWEET_LENGTH = 140;

@interface ComposeTweetViewController ()

- (void)showRecipientView;
- (void)hideRecipientView;

- (void)enableSendButtonFromInterface;
- (void)enableSendButtonFromText:(NSString *)text;
- (void)enableSendButtonFromText:(NSString *)text
                    andRecipient:(NSString *)recipient;

- (void)updateCharacterCountFromInterface;
- (void)updateCharacterCountFromText:(NSString *)text;

@property (nonatomic, copy) NSString * currentSender;
@property (nonatomic, copy) NSString * textViewText;

@end

@implementation ComposeTweetViewController

@synthesize delegate, sendButton, cancelButton, currentSender, textViewText;

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
    
    [currentSender release];
    [textViewText release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    displayingActivity = NO;
    
    if (hideRecipientView)
        [self hideRecipientView];
    
    if (self.currentSender)
        accountLabel.text =
            [NSString stringWithFormat:@"@%@", self.currentSender];
    if (self.textViewText)
        textView.text = self.textViewText;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self enableSendButtonFromInterface];

    [self updateCharacterCountFromText:textView.text];

    CGRect characterCountFrame = characterCount.frame;
    // hack -- this needs to be 167 when displayed, but 104 after a rotation
    // <sarcasm>it makes sense</sarcasm>
    characterCountFrame.origin.y = 167;
    characterCount.frame = characterCountFrame;

    [textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [recipientTextField resignFirstResponder];
    [textView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    NSLog(@"Did rotate to interface orientation.");
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown) {

        if (!recipientView.hidden) {
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
    } else {
        if (!recipientView.hidden) {
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

    if (recipientView.hidden)
        [self enableSendButtonFromText:s];
    else
        [self enableSendButtonFromText:s andRecipient:recipientTextField.text];

    return YES;
}

#pragma mark Button actions

- (IBAction)userDidSave
{
    if (recipientView.hidden)
        [delegate userWantsToSendTweet:textView.text];
    else
        [delegate userWantsToSendDirectMessage:textView.text
                                   toRecipient:recipientTextField.text];
}

- (IBAction)userDidCancel
{
    if (textView.text.length == 0) {
        if (recipientView.hidden)
            [delegate userDidCancelComposingTweet:textView.text];
        else
            [delegate
                userDidCancelComposingDirectMessage:textView.text
                                        toRecipient:recipientTextField.text];
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

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:  // save as draft
            if (recipientView.hidden)
                [delegate userDidSaveTweetDraft:textView.text];
            else
                [delegate
                    userDidSaveDirectMessageDraft:textView.text
                                      toRecipient:recipientTextField.text];
            break;
        case 1:  // user confirmed the cancel
            if (recipientView.hidden)
                [delegate userDidCancelComposingTweet:textView.text];
            else {
                NSString * recipient = recipientTextField.text;
                [delegate userDidCancelComposingDirectMessage:textView.text
                                                  toRecipient:recipient];
            }
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
    if (recipientView.hidden)
        [self enableSendButtonFromText:textView.text];
    else
        [self enableSendButtonFromText:textView.text
                          andRecipient:recipientTextField.text];
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

@end
