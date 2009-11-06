//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetViewController.h"
#import "UIColor+TwitchColors.h"
#import "RotatableTabBarController.h"
#import "NSString+UrlAdditions.h"
#import "SettingsReader.h"

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

- (void)enableUrlShorteningButtonFromInterface;
- (void)enableUrlShorteningButtonFromText:(NSString *)text;

- (void)saveCurrentStateAsDraft;

- (void)displayForOrientation:(UIInterfaceOrientation)orientation;
- (void)displayForPortraitMode;

- (BOOL)composingDirectMessage;

- (void)initializeView;
- (BOOL)viewNeedsInitialization;
- (void)setViewNeedsInitialization:(BOOL)needsInitialization;
- (void)resetView;
- (void)setTitleView;

- (void)clearTweet;

- (NSArray *)extractShortenableUrls:(NSString *)text;

- (void)displayActivityView:(UIView *)activityView;
- (void)hideActivityView:(UIView *)activityView;

- (void)initializePhotoUploadView;
- (void)initializeLinkShorteningView;

+ (NSUInteger)minimumAllowedUrlLength;

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

    [shortenLinksButton release];
    [characterCountPortrait release];
    [characterCountLandscape release];

    [portraitHeaderView release];
    [portraitTitleLabel release];
    [portraitAccountLabel release];

    [recipientView release];
    [recipientTextField release];
    [recipientToLabel release];
    [recipientBackgroundView release];
    [addRecipientButton release];

    [photoUploadView release];
    [photoUploadProgressView release];

    [urlShorteningView release];

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
    if (text.length)
        [self saveCurrentStateAsDraft];
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
    if (text.length)
        [self saveCurrentStateAsDraft];
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
    if (text.length)
        [self saveCurrentStateAsDraft];
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
    if (text.length)
        [self saveCurrentStateAsDraft];
}

- (void)setRecipient:(NSString *)recipient
{
    recipientTextField.text = recipient;
    [textView becomeFirstResponder];
}

- (void)addTextToMessage:(NSString *)text
{
    NSString * current = textView.text;

    NSCharacterSet * whitespace =
        [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSRange where = [current rangeOfCharacterFromSet:whitespace
                                             options:NSBackwardsSearch];
    NSRange notFound = NSMakeRange(NSNotFound, 0);

    NSString * padding =
        (current.length == 0 || !NSEqualRanges(where, notFound)) ?
        @"" :  // no padding needed
        @" ";  // padding needed

    textView.text = [current stringByAppendingFormat:@"%@%@", padding, text];

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromInterface];
    [self enableUrlShorteningButtonFromInterface];

    [self saveCurrentStateAsDraft];
}

- (void)replaceOccurrencesOfString:(NSString *)oldString
                        withString:(NSString *)newString
{
    NSString * s =
        [textView.text stringByReplacingOccurrencesOfString:oldString
                                                 withString:newString];
    textView.text = s;

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromInterface];
    [self enableUrlShorteningButtonFromInterface];

    [self saveCurrentStateAsDraft];
}

- (void)displayPhotoUploadView
{
    if (!photoUploadViewHasBeenInitialized) {
        [self initializePhotoUploadView];
        photoUploadViewHasBeenInitialized = YES;
    }

    photoUploadView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:photoUploadView
                             cache:YES];

    photoUploadView.alpha = 0.8;
    UIView * keyboardView = [[UIApplication sharedApplication] keyboardView];
    UIView * keyView =
        keyboardView ?
        [keyboardView superview] :
        self.navigationController.view;
    [keyView addSubview:photoUploadView];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    [UIView commitAnimations];

    displayingActivity = YES;
}

- (void)updatePhotoUploadProgress:(CGFloat)uploadProgress
{
    if (photoUploadProgressView.progress != uploadProgress)
        photoUploadProgressView.progress = uploadProgress;
}

- (void)hidePhotoUploadView
{
    photoUploadView.alpha = 0.8;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:photoUploadView
                             cache:YES];

    photoUploadView.alpha = 0.0;
    UIStatusBarStyle statusBarStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIStatusBarStyleBlackOpaque : UIStatusBarStyleDefault;
    [[UIApplication sharedApplication]
        setStatusBarStyle:statusBarStyle animated:NO];

    [UIView commitAnimations];

    displayingActivity = NO;
}

- (void)displayUrlShorteningView
{
    if (!urlShorteningViewHasBeenInitialized) {
        [self initializeLinkShorteningView];
        urlShorteningViewHasBeenInitialized = YES;
    }
    [self displayActivityView:urlShorteningView];
    displayingActivity = YES;
}

- (void)hideUrlShorteningView
{
    [self hideActivityView:urlShorteningView];
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

    photoUploadViewHasBeenInitialized = NO;
    urlShorteningViewHasBeenInitialized = NO;

    UIBarButtonItem * characterCountButton =
        [[UIBarButtonItem alloc] initWithCustomView:characterCountPortrait];
    NSArray * toolbarItems = toolbar.items;
    toolbar.items = [toolbarItems arrayByAddingObject:characterCountButton];
    [characterCountButton release];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        characterCountLandscape.textColor = [UIColor whiteColor];
        characterCountLandscape.backgroundColor =
            [UIColor defaultDarkThemeCellColor];
        textView.keyboardAppearance = UIKeyboardAppearanceAlert;
        recipientBackgroundView.image =
            [UIImage imageNamed:@"ComposeRecipientGradientDarkTheme.png"];
        recipientToLabel.textColor = [UIColor twitchLightLightGrayColor];
        recipientToLabel.shadowColor = [UIColor twitchDarkDarkGrayColor];
        recipientTextField.textColor = [UIColor whiteColor];
        recipientTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    } else {
        characterCountLandscape.textColor = [UIColor twitchGrayColor];
        characterCountLandscape.backgroundColor = [UIColor whiteColor];
    }

    [self setViewNeedsInitialization:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self enableSendButtonFromInterface];
    [self updateCharacterCountFromText:textView.text];

    if ([self viewNeedsInitialization])
        [self initializeView];
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
            textViewFrame.size.height = 125;
            textView.frame = textViewFrame;

            CGRect addRecipientButtonFrame = addRecipientButton.frame;
            addRecipientButtonFrame.origin.y = 0;
            addRecipientButton.frame = addRecipientButtonFrame;
        } else {
            CGRect textViewFrame = textView.frame;
            textViewFrame.size.height = 165.0;
            textView.frame= textViewFrame;
        }

        characterCountLandscape.alpha = 1.0;
        toolbar.hidden = YES;

        self.navigationItem.titleView = nil;
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

        CGRect addRecipientButtonFrame = addRecipientButton.frame;
        addRecipientButtonFrame.origin.y = 5;
        addRecipientButton.frame = addRecipientButtonFrame;
    }

    characterCountLandscape.alpha = 0.0;
    toolbar.hidden = NO;

    self.navigationItem.titleView = portraitHeaderView;
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
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text
{
    if (displayingActivity)
        return NO;

    NSString * s = [textView.text stringByReplacingCharactersInRange:range
                                                          withString:text];

    [self updateCharacterCountFromText:s];
    [self enableUrlShorteningButtonFromText:s];

    if ([self composingDirectMessage]) {
        [self enableSendButtonFromText:s andRecipient:recipientTextField.text];
        [delegate userDidSaveDirectMessageDraft:s
                                    toRecipient:recipientTextField.text];
    } else {
        [self enableSendButtonFromText:s];
        [delegate userDidSaveTweetDraft:s];
    }

    return YES;
}

#pragma mark Button actions

- (void)userDidSend
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

- (IBAction)chooseDirectMessageRecipient
{
    [delegate userWantsToSelectDirectMessageRecipient];
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

    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

    [sheet showInView:self.view];
}

- (IBAction)choosePhoto
{
    [delegate userWantsToSelectPhoto];
}

- (IBAction)shortenLinks
{
    NSArray * urls = [self extractShortenableUrls:textView.text];
    [delegate userWantsToShortenUrls:[NSSet setWithArray:urls]];
}

- (IBAction)choosePerson
{
    [delegate userWantsToSelectPerson];
}

- (void)userDidCancelPhotoUpload
{
    [delegate userDidCancelPhotoUpload];
}

- (void)userDidCancelUrlShortening
{
    [delegate userDidCancelUrlShortening];
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

- (void)updateCharacterCountFromInterface
{
    [self updateCharacterCountFromText:textView.text];
}

- (void)updateCharacterCountFromText:(NSString *)text
{
    NSString * characterCount =
        [NSString stringWithFormat:@"%d", MAX_TWEET_LENGTH - text.length];

    characterCountPortrait.text = characterCount;
    characterCountLandscape.text = characterCount;
}

- (void)enableUrlShorteningButtonFromInterface
{
    [self enableUrlShorteningButtonFromText:textView.text];
}

- (void)enableUrlShorteningButtonFromText:(NSString *)text
{
    shortenLinksButton.enabled = [self extractShortenableUrls:text].count > 0;
}

- (void)saveCurrentStateAsDraft
{
    if ([self composingDirectMessage])
        [delegate userDidSaveDirectMessageDraft:textView.text
                                    toRecipient:recipientTextField.text];
    else
        [delegate userDidSaveTweetDraft:textView.text];
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
    [self enableUrlShorteningButtonFromInterface];

    UIInterfaceOrientation orientation =
        [[RotatableTabBarController instance] effectiveOrientation];
    [self displayForOrientation:orientation];

    [self setTitleView];

    // set the colors for the current theme
    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        toolbar.barStyle = UIBarStyleBlack;
        textView.backgroundColor = [UIColor defaultDarkThemeCellColor];
        textView.textColor = [UIColor whiteColor];
    }
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
    [self enableUrlShorteningButtonFromInterface];
}

- (void)setTitleView
{
    if ([self composingDirectMessage])
        portraitTitleLabel.text =
            NSLocalizedString(@"composetweet.view.header.dm.title", @"");
    else {
        if (currentRecipient) {  // format for a public reply
            NSString * titleFormatString =
                NSLocalizedString(@"composetweet.view.header.tweet.reply.title",
                        @"");
            portraitTitleLabel.text =
                [NSString stringWithFormat:titleFormatString, currentRecipient];
        } else  // format for a regular tweet
            portraitTitleLabel.text =
                NSLocalizedString(
                        @"composetweet.view.header.tweet.update.title", @"");
    }

    NSString * accountFormatString =
        NSLocalizedString(@"composetweet.view.header.tweet.account", @"");
    portraitAccountLabel.text =
        [NSString stringWithFormat:accountFormatString, currentSender];

    //landscapeTitleLabel.text =
    self.navigationItem.title =
        [NSString stringWithFormat:@"%@ %@", portraitTitleLabel.text,
        portraitAccountLabel.text];
}

- (void)clearTweet
{
    BOOL cleared =
        [self composingDirectMessage] ?
        [delegate clearCurrentDirectMessageDraftTo:recipientTextField.text] :
        [delegate clearCurrentTweetDraft];

    if (cleared) {
        if ([self composingDirectMessage]) {
            NSString * recipient = [recipientTextField.text retain];
            self.currentRecipient = nil;
            [self resetView];
            recipientTextField.text = recipient;
            [recipient release];
        } else {
            self.currentRecipient = nil;
            [self resetView];
        }
    }
}

- (NSArray *)extractShortenableUrls:(NSString *)text
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"SELF.length > %d", [[self class] minimumAllowedUrlLength]];
    return [[text extractUrls] filteredArrayUsingPredicate:predicate];
}

- (void)displayActivityView:(UIView *)activityView
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
}

- (void)hideActivityView:(UIView *)activityView
{
    activityView.alpha = 0.8;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:activityView
                             cache:YES];

    activityView.alpha = 0.0;
    UIStatusBarStyle statusBarStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIStatusBarStyleBlackOpaque : UIStatusBarStyleDefault;
    [[UIApplication sharedApplication]
        setStatusBarStyle:statusBarStyle animated:NO];

    [UIView commitAnimations];
}

- (void)initializePhotoUploadView
{
    static const NSInteger BUTTON_WIDTH = 134;
    CGRect buttonFrame =
        CGRectMake((320 - BUTTON_WIDTH) / 2, 156, BUTTON_WIDTH, 46);
    UIButton * photoUploadCancelButton =
        [[UIButton alloc] initWithFrame:buttonFrame];
    NSString * cancelButtonTitle =
        NSLocalizedString(@"composetweet.cancelshortening", @"");
    [photoUploadCancelButton setTitle:cancelButtonTitle
        forState:UIControlStateNormal];
    UIImage * normalImage =
        [[UIImage imageNamed:@"CancelButton.png"]
        stretchableImageWithLeftCapWidth:13.0 topCapHeight:0.0];
    [photoUploadCancelButton setBackgroundImage:normalImage
        forState:UIControlStateNormal];
    photoUploadCancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [photoUploadCancelButton setTitleColor:[UIColor whiteColor]
        forState:UIControlStateNormal];
    [photoUploadCancelButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateHighlighted];
    [photoUploadCancelButton setTitleShadowColor:[UIColor twitchDarkGrayColor]
        forState:UIControlStateNormal];
    photoUploadCancelButton.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    [photoUploadCancelButton
        addTarget:self action:@selector(userDidCancelPhotoUpload)
        forControlEvents:UIControlEventTouchUpInside];

    [photoUploadView addSubview:photoUploadCancelButton];
    [photoUploadCancelButton release];
}

- (void)initializeLinkShorteningView
{
    static const NSInteger BUTTON_WIDTH = 134;
    CGRect buttonFrame =
        CGRectMake((320 - BUTTON_WIDTH) / 2, 135, BUTTON_WIDTH, 46);
    UIButton * linkShorteningCancelButton =
        [[UIButton alloc] initWithFrame:buttonFrame];
    NSString * cancelButtonTitle =
        NSLocalizedString(@"composetweet.cancelshortening", @"");
    [linkShorteningCancelButton setTitle:cancelButtonTitle
        forState:UIControlStateNormal];
    UIImage * normalImage =
        [[UIImage imageNamed:@"CancelButton.png"]
        stretchableImageWithLeftCapWidth:13.0 topCapHeight:0.0];
    [linkShorteningCancelButton setBackgroundImage:normalImage
        forState:UIControlStateNormal];
    linkShorteningCancelButton.titleLabel.font =
        [UIFont boldSystemFontOfSize:17];
    [linkShorteningCancelButton setTitleColor:[UIColor whiteColor]
        forState:UIControlStateNormal];
    [linkShorteningCancelButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateHighlighted];
    [linkShorteningCancelButton
        setTitleShadowColor:[UIColor twitchDarkGrayColor]
        forState:UIControlStateNormal];
    linkShorteningCancelButton.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    [linkShorteningCancelButton
        addTarget:self action:@selector(userDidCancelUrlShortening)
        forControlEvents:UIControlEventTouchUpInside];

    [urlShorteningView addSubview:linkShorteningCancelButton];
    [linkShorteningCancelButton release];
}

+ (NSUInteger)minimumAllowedUrlLength
{
    // Based on the length of a Flickr URL, for example:
    //   http://flic.kr/p/77UDDW
    // which is 23 characters.
    return 25;
}

@end
