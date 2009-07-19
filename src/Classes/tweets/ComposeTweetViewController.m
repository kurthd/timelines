//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"

static const NSInteger MAX_TWEET_LENGTH = 140;

@interface ComposeTweetViewController ()

- (void)disableForm;
- (void)enableForm;

@end

@implementation ComposeTweetViewController

@synthesize delegate;

- (void)dealloc
{
    [textView release];
    [navigationBar release];
    [toolbar release];
    [cancelButton release];
    [sendButton release];
    [characterCount release];
    [accountLabel release];
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

    sendButton.enabled =
        textView.text.length > 0 && textView.text.length <= MAX_TWEET_LENGTH;
    if (!displayingActivity)
        [textView becomeFirstResponder];
        
    CGRect characterCountFrame = characterCount.frame;
     // hack -- this needs to be 210 when displayed, but 133 after a rotation
    characterCountFrame.origin.y = 210;
    characterCount.frame = characterCountFrame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [textView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation {

    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortrait) {

        CGRect textViewFrame = textView.frame;
        textViewFrame.size.width = 320;
        textViewFrame.size.height = 178;
        textView.frame = textViewFrame;

        CGRect characterCountFrame = characterCount.frame;
        characterCountFrame.origin.y = 133;
        characterCount.frame = characterCountFrame;
        characterCount.textColor = [UIColor whiteColor];

        toolbar.hidden = NO;
    } else {
        CGRect textViewFrame = textView.frame;
        textViewFrame.size.width = 480;
        textViewFrame.size.height = 95;
        textView.frame = textViewFrame;

        CGRect characterCountFrame = characterCount.frame;
        characterCountFrame.origin.y = 173;
        characterCount.frame = characterCountFrame;
        characterCount.textColor = [UIColor twitchGrayColor];

        toolbar.hidden = YES;
    }

	return YES;
}

- (void)setTitle:(NSString *)title
{
    navigationBar.topItem.title = title;
}

- (void)setUsername:(NSString *)username
{
    accountLabel.text = [NSString stringWithFormat:@"@%@", username];
}

- (void)promptWithText:(NSString *)text
{
    sendButton.enabled = text.length > 0 && text.length <= MAX_TWEET_LENGTH;
    cancelButton.enabled = YES;

    textView.text = text;

    characterCount.text = [NSString stringWithFormat:@"%d",
        MAX_TWEET_LENGTH - text.length];
}

- (void)addTextToMessage:(NSString *)text
{
    NSString * current = textView.text;
    textView.text = [current stringByAppendingFormat:@" %@", text];
    characterCount.text =
        [NSString stringWithFormat:@"%d",
        MAX_TWEET_LENGTH - textView.text.length];
    sendButton.enabled =
        textView.text.length > 0 && textView.text.length <= MAX_TWEET_LENGTH;
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

#pragma mark UITextViewDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"Called");
    return !displayingActivity;
}

- (BOOL)textView:(UITextView *)aTextView
    shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (displayingActivity)
        return NO;

    NSString * s = [textView.text stringByReplacingCharactersInRange:range
                                                          withString:text];

    characterCount.text =
        [NSString stringWithFormat:@"%d", MAX_TWEET_LENGTH - s.length];
    sendButton.enabled = s.length > 0 && s.length <= MAX_TWEET_LENGTH;

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

@end
