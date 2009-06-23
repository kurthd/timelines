//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"

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
    [cancelButton release];
    [sendButton release];
    [characterCount release];
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

- (void)promptWithText:(NSString *)text
{
    sendButton.enabled = NO;
    cancelButton.enabled = YES;

    textView.text = text;

    characterCount.text = [NSString stringWithFormat:@"%d",
        MAX_TWEET_LENGTH - text.length];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];  // Releases the view if it doesn't have a
                                      // superview

    // Release anything that's not essential, such as cached data
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (BOOL)textView:(UITextView *)aTextView
    shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString * s = [textView.text stringByReplacingCharactersInRange:range
                                                          withString:text];

    characterCount.text = [NSString stringWithFormat:@"%d",
        MAX_TWEET_LENGTH - s.length];
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
