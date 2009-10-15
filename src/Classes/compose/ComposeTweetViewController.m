//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"
#import "RotatableTabBarController.h"

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

- (void)displayForOrientation:(UIInterfaceOrientation)orientation;
- (void)displayForPortraitMode;
- (void)correctCharacterCountFrameWhenDisplayed;

- (BOOL)composingDirectMessage;

- (void)initializeView;
- (BOOL)viewNeedsInitialization;
- (void)setViewNeedsInitialization:(BOOL)needsInitialization;
- (void)resetView;
- (void)setTitleView;

- (void)clearTweet;

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

#pragma mark Public implementation

- (void)composeTweet:(NSString *)text from:(NSString *)sender
{
    self.currentSender = sender;
    self.currentRecipient = nil;
    self.textViewText = text;

    textView.text = text;
    recipientTextField.text = @"";

    [self hideRecipientView];
    [self setViewNeedsInitialization:YES];
}

- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
           inReplyTo:(NSString *)recipient
{
    self.currentSender = sender;
    self.currentRecipient = recipient;
    self.textViewText = text;

    textView.text = text;
    recipientTextField.text = @"";

    [self hideRecipientView];
    [self setViewNeedsInitialization:YES];
}

- (void)composeDirectMessage:(NSString *)text from:(NSString *)sender
{
    self.currentSender = sender;
    self.currentRecipient = nil;
    self.textViewText = text;

    textView.text = text;
    recipientTextField.text = @"";

    [self showRecipientView];
    [self setViewNeedsInitialization:YES];
}

- (void)composeDirectMessage:(NSString *)text
                        from:(NSString *)sender
                          to:(NSString *)recipient
{
    self.currentSender = sender;
    self.textViewText = text;
    self.currentRecipient = recipient;

    textView.text = text;
    recipientTextField.text = recipient;

    [self showRecipientView];
    [self setViewNeedsInitialization:YES];
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

    activityView.alpha = 0.8;
    UIView * keyboardView = [[UIApplication sharedApplication] keyboardView];
    UIView * keyView = keyboardView ? [keyboardView superview] : self.view;
    [keyView addSubview:activityView];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    [UIView commitAnimations];

    displayingActivity = YES;
}

- (void)updateActivityProgress:(CGFloat)uploadProgress
{
    if (activityProgressView.progress != uploadProgress)
        activityProgressView.progress = uploadProgress;
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

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (hideRecipientView)
        [self hideRecipientView];

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

    [self setViewNeedsInitialization:YES];
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

    if ([self viewNeedsInitialization])
        [self initializeView];
}

- (void)correctCharacterCountFrameWhenDisplayed
{
    CGRect characterCountFrame = characterCount.frame;
    // hack -- this needs to be 167 when displayed, but 104 after a rotation
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    characterCountFrame.origin.y = landscape ? 80 : 167;
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
    [self displayForOrientation:orientation];
}

- (void)displayForOrientation:(UIInterfaceOrientation)orientation
{
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
    characterCountFrame.origin.y = 167;
    characterCount.frame = characterCountFrame;

    characterCount.textColor = [UIColor whiteColor];
    characterCount.backgroundColor = [UIColor clearColor];

    toolbar.hidden = NO;
    accountLabel.hidden = NO;
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
                                    /*dismissView:NO*/];
    } else {
        [self enableSendButtonFromText:s];
        [delegate userDidSaveTweetDraft:s /*dismissView:NO*/];
    }

    return YES;
}

#pragma mark Button actions

- (IBAction)userDidSend
{
    if ([self composingDirectMessage])
        [delegate userWantsToSendDirectMessage:textView.text
                                   toRecipient:recipientTextField.text];
    else
        [delegate userWantsToSendTweet:textView.text];
}

- (IBAction)userDidClose
{
    if (textView.text.length == 0)
        [self clearTweet];

    [delegate closeView];
}

- (IBAction)promptToClearTweet
{
    NSString * cancelTitle =
        NSLocalizedString(@"composetweet.clear.confirm.cancel", @"");
    NSString * clearTitle =
        NSLocalizedString(@"composetweet.clear.confirm.clear", @"");
 
    UIActionSheet * sheet =
        [[UIActionSheet alloc] initWithTitle:nil
                                    delegate:self
                           cancelButtonTitle:cancelTitle
                      destructiveButtonTitle:clearTitle
                           otherButtonTitles:nil];

    [sheet showInView:self.view];
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
    if (buttonIndex == 0) {
        [self clearTweet];
        [self initializeView];
    }
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

- (void)initializeView
{
    if (hideRecipientView || recipientTextField.text.length > 0)
        [textView becomeFirstResponder];
    else
        [recipientTextField becomeFirstResponder];

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromInterface];

    UIInterfaceOrientation orientation =
        [[RotatableTabBarController instance] effectiveOrientation];
    [self displayForOrientation:orientation];

    [self setTitleView];
}

- (BOOL)viewNeedsInitialization
{
    return viewNeedsInitialization;
}

- (void)setViewNeedsInitialization:(BOOL)needsInitialization
{
    viewNeedsInitialization = needsInitialization;
}

- (void)resetView
{
    if ([self composingDirectMessage])
        recipientTextField.text = @"";
    textView.text = @"";

    [self setTitleView];
    [self updateCharacterCountFromInterface];
    [self enableSendButtonFromInterface];
}

- (void)setTitleView
{
    self.navigationItem.titleView = headerView;

    if ([self composingDirectMessage])
        titleLabel.text =
            NSLocalizedString(@"composetweet.view.header.dm.title", @"");
    else {
        if (currentRecipient) {  // format for a public reply
            NSString * titleFormatString =
                NSLocalizedString(@"composetweet.view.header.tweet.reply.title",
                        @"");
            titleLabel.text =
                [NSString stringWithFormat:titleFormatString, currentRecipient];
        } else  // format for a regular tweet
            titleLabel.text =
                NSLocalizedString(
                        @"composetweet.view.header.tweet.update.title", @"");
    }

    NSString * accountFormatString =
        NSLocalizedString(@"composetweet.view.header.tweet.account", @"");
    accountLabel.text =
        [NSString stringWithFormat:accountFormatString, currentSender];
}

- (void)clearTweet
{
    BOOL cleared =
        [self composingDirectMessage] ?
        [delegate clearCurrentDirectMessageDraftTo:recipientTextField.text] :
        [delegate clearCurrentTweetDraft];

    if (cleared) {
        self.currentRecipient = nil;
        [self resetView];
    }
}

@end
