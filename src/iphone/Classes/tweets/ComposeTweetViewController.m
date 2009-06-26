//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"

static const NSInteger MAX_TWEET_LENGTH = 140;

@interface UIApplication (KeyboardView)

- (UIView *)keyboardView;

@end

@implementation UIApplication (KeyboardView)

- (UIView *)keyboardView
{
    NSArray * windows = [self windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])
        for (UIView *view in [window subviews])
            if (!strcmp(object_getClassName(view), "UIKeyboard"))
                return view;
    
    return nil;
}

@end


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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [textView becomeFirstResponder];
}

- (void)setTitle:(NSString *)title
{
    NSLog(@"My navigation item is: '%@'", self.navigationItem);
    navigationBar.topItem.title = title;
}

- (void)setUsername:(NSString *)username
{
    accountLabel.text = [NSString stringWithFormat:@"@%@", username];
}

- (void)promptWithText:(NSString *)text
{
    sendButton.enabled = NO;
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
    [[[UIApplication sharedApplication] keyboardView].superview
        addSubview:activityView];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    [UIView commitAnimations];
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
}

#pragma mark UITextViewDelegate implementation

- (BOOL)textView:(UITextView *)aTextView
    shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
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
    [delegate userDidCancel];
}

- (IBAction)choosePhoto
{
    [delegate userWantsToSelectPhoto];
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
