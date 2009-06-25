//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetDisplayMgr.h"
#import "ComposeTweetViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsActivatedPublisher.h"
#import "TwitPicImageSender.h"

@interface ComposeTweetDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) ComposeTweetViewController *
    composeTweetViewController;

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) TwitPicImageSender * imageSender;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsUpdatePublisher;

@property (nonatomic, copy) NSString * recipient;
@property (nonatomic, copy) NSString * origUsername;
@property (nonatomic, copy) NSString * origTweetId;

- (void)displayImagePicker:(UIImagePickerControllerSourceType)source;

@end

@implementation ComposeTweetDisplayMgr

@synthesize rootViewController, composeTweetViewController;
@synthesize service, imageSender, credentialsUpdatePublisher;
@synthesize delegate;
@synthesize recipient, origUsername, origTweetId;

- (void)dealloc
{
    self.delegate = nil;
    self.rootViewController = nil;
    self.composeTweetViewController = nil;
    self.service = nil;
    self.imageSender = nil;
    self.credentialsUpdatePublisher = nil;
    self.recipient = nil;
    self.origUsername = nil;
    self.origTweetId = nil;
    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                     imageSender:(TwitPicImageSender *)anImageSender
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.service = aService;
        self.service.delegate = self;

        self.imageSender = anImageSender;
        self.imageSender.delegate = self;

        credentialsUpdatePublisher = [[CredentialsActivatedPublisher alloc]
            initWithListener:self action:@selector(setCredentials:)];
    }

    return self;
}

- (void)composeTweet
{
    [self composeTweetWithText:@""];
}

- (void)composeTweetWithText:(NSString *)tweet
{
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    [self.composeTweetViewController
        setTitle:NSLocalizedString(@"composetweet.view.title", @"")];
    [self.composeTweetViewController setUsername:service.credentials.username];
    [self.composeTweetViewController promptWithText:tweet];

    self.recipient = nil;
    self.origTweetId = nil;
    self.origUsername = nil;
}

- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user
{
    [self composeReplyToTweet:tweetId
                     fromUser:user
                     withText:[NSString stringWithFormat:@"@%@ ", user]];
}

- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user
                   withText:(NSString *)text
{
    [self composeTweetWithText:text];
    self.origTweetId = tweetId;
    self.origUsername = user;

    [self.composeTweetViewController
        setTitle:[NSString stringWithFormat:@"@%@", user]];
}

- (void)composeDirectMessageTo:(NSString *)username
{
    [self composeDirectMessageTo:username withText:@""];
}

- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)tweet
{
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    [self.composeTweetViewController setUsername:service.credentials.username];
    [self.composeTweetViewController promptWithText:tweet];
    [self.composeTweetViewController setTitle:
        [NSString stringWithFormat:
        NSLocalizedString(@"composedirectmessage.view.title", @""), username]];

    self.recipient = username;
    self.origTweetId = nil;
    self.origUsername = nil;
}

#pragma mark Credentials notifications

- (void)setCredentials:(TwitterCredentials *)credentials
{
    self.service.credentials = credentials;
}

#pragma mark ComposeTweetViewControllerDelegate implementation

- (void)userDidCancel
{
    [self.delegate userDidCancelComposingTweet];
    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)userDidSave:(NSString *)tweet
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    if (recipient) {
        [self.delegate userIsSendingDirectMessage:tweet to:self.recipient];
        [self.service sendDirectMessage:tweet to:self.recipient];
    } else {
        if (self.origTweetId) {  // sending a public reply
            [self.delegate userIsReplyingToTweet:self.origTweetId
                                        fromUser:self.origUsername
                                        withText:tweet];
            [self.service sendTweet:tweet inReplyTo:self.origTweetId];
        } else {
            [self.delegate userIsSendingTweet:tweet];
            [self.service sendTweet:tweet];
        }
    }
}

- (void)userWantsToSelectPhoto
{
    // to help with readability
    UIImagePickerControllerSourceType photoLibrary =
        UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerControllerSourceType camera =
        UIImagePickerControllerSourceTypeCamera;

    UIImagePickerControllerSourceType source;

    BOOL libraryAvailable =
        [UIImagePickerController isSourceTypeAvailable:photoLibrary];
    BOOL cameraAvailable =
        [UIImagePickerController isSourceTypeAvailable:camera];

    if (cameraAvailable && libraryAvailable) {
        NSString * cancelButton =
            NSLocalizedString(@"imagepicker.choose.cancel", @"");
        NSString * cameraButton =
            NSLocalizedString(@"imagepicker.choose.camera", @"");
        NSString * photosButton =
            NSLocalizedString(@"imagepicker.choose.photos", @"");
        
        UIActionSheet * sheet =
            [[UIActionSheet alloc] initWithTitle:nil
                                        delegate:self
                               cancelButtonTitle:cancelButton
                          destructiveButtonTitle:nil
                               otherButtonTitles:cameraButton,
                                                 photosButton, nil];
        [sheet showInView:self.rootViewController.view];
    } else {
        if (cameraAvailable)
            source = camera;
        else
            source = photoLibrary;

        [self displayImagePicker:source];
    }
}

#pragma mark TwitterServiceDelegate implementation

- (void)tweetSentSuccessfully:(Tweet *)tweet
{
    [self.delegate userDidSendTweet:tweet];
}

- (void)failedToSendTweet:(NSString *)tweet error:(NSError *)error
{
    NSString * title = NSLocalizedString(@"sendtweet.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];

    [self.delegate userFailedToSendTweet:tweet];
}

- (void)tweet:(Tweet *)tweet sentInReplyTo:(NSString *)tweetId
{
    [self.delegate userDidReplyToTweet:self.origTweetId
                              fromUser:self.origUsername
                             withTweet:tweet];
}

- (void)failedToReplyToTweet:(NSString *)tweetId
                    withText:(NSString *)text
                       error:(NSError *)error
{
    NSString * title = NSLocalizedString(@"sendtweet.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];

    [self.delegate userFailedToReplyToTweet:self.origTweetId
                                   fromUser:self.origUsername
                                   withText:text];
}

- (void)directMessage:(DirectMessage *)dm sentToUser:(NSString *)username
{
    [self.delegate userDidSendDirectMessage:dm];
}

- (void)failedToSendDirectMessage:(NSString *)text
                           toUser:(NSString *)username
                            error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"directmessage.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];

    [self.delegate userFailedToSendDirectMessage:text to:username];
}

#pragma mark TwitPicImageSenderDelegate implementation

- (void)sender:(TwitPicImageSender *)sender didPostImageToUrl:(NSString *)url
{
    NSLog(@"Successfully posted image to URL: '%@'.", url);

    [self.composeTweetViewController hideActivityView];
    [self.composeTweetViewController addTextToMessage:url];
}

- (void)sender:(TwitPicImageSender *)sender failedToPostImage:(NSError *)error
{
    NSLog(@"Failed to post image to URL: '%@'.", error);

    NSString * title = NSLocalizedString(@"imageupload.failed.title", @"");

    [[UIAlertView simpleAlertViewWithTitle:title
                                   message:error.localizedDescription] show];

    [self.composeTweetViewController hideActivityView];
}

#pragma mark UIImagePickerControllerDelegate implementation

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image)
         image = [info valueForKey:UIImagePickerControllerOriginalImage];

    [imageSender sendImage:image withCredentials:service.credentials];
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
    [self.composeTweetViewController displayActivityView];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:  // camera
            [self displayImagePicker:UIImagePickerControllerSourceTypeCamera];
            break;
        case 1:  // library
            [self displayImagePicker:
                UIImagePickerControllerSourceTypePhotoLibrary];
            break;
    }

    [actionSheet autorelease];
}

#pragma mark UIImagePicker helper methods

- (void)displayImagePicker:(UIImagePickerControllerSourceType)source
{
    UIImagePickerController * imagePicker =
        [[UIImagePickerController alloc] init];

    imagePicker.delegate = self;
    imagePicker.allowsImageEditing = YES;
    imagePicker.sourceType = source;

    [self.composeTweetViewController
        presentModalViewController:imagePicker animated:YES];
    [imagePicker release];
}


#pragma mark Accessors

- (ComposeTweetViewController *)composeTweetViewController
{
    if (!composeTweetViewController) {
        composeTweetViewController = [[ComposeTweetViewController alloc]
            initWithNibName:@"ComposeTweetView" bundle:nil];
        composeTweetViewController.delegate = self;
    }

    return composeTweetViewController;
}

@end
