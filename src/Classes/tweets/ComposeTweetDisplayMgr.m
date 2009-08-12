//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetDisplayMgr.h"
#import "ComposeTweetViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "TwitPicImageSender.h"
#import "TweetDraft.h"
#import "DirectMessageDraft.h"
#import "TweetDraftMgr.h"

@interface ComposeTweetDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) ComposeTweetViewController *
    composeTweetViewController;

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) TwitPicImageSender * imageSender;
@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsUpdatePublisher;
@property (nonatomic, retain) CredentialsSetChangedPublisher *
    credentialsSetChangedPublisher;

//@property (nonatomic, copy) NSString * recipient;
@property (nonatomic, copy) NSString * origUsername;
@property (nonatomic, copy) NSString * origTweetId;

@property (nonatomic, retain) TweetDraftMgr * draftMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

- (void)promptForPhotoSource:(UIViewController *)controller;
- (void)displayImagePicker:(UIImagePickerControllerSourceType)source
                controller:(UIViewController *)controller;

@end

@implementation ComposeTweetDisplayMgr

@synthesize rootViewController, composeTweetViewController;
@synthesize service, imageSender;
@synthesize credentialsUpdatePublisher, credentialsSetChangedPublisher;
@synthesize logInDisplayMgr, context;
@synthesize delegate;
@synthesize /*recipient,*/ origUsername, origTweetId;
@synthesize draftMgr;

- (void)dealloc
{
    self.delegate = nil;
    self.rootViewController = nil;
    self.composeTweetViewController = nil;
    self.service = nil;
    self.imageSender = nil;
    self.credentialsUpdatePublisher = nil;
    self.credentialsSetChangedPublisher = nil;
    //self.recipient = nil;
    self.origUsername = nil;
    self.origTweetId = nil;
    self.draftMgr = nil;
    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                     imageSender:(TwitPicImageSender *)anImageSender
                         context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.service = aService;
        self.service.delegate = self;

        self.imageSender = anImageSender;
        self.imageSender.delegate = self;

        self.context = aContext;

        credentialsUpdatePublisher = [[CredentialsActivatedPublisher alloc]
            initWithListener:self action:@selector(setCredentials:)];
        credentialsSetChangedPublisher =
            [[CredentialsSetChangedPublisher alloc]
                initWithListener:self
                          action:@selector(credentialsSetChanged:added:)];

        fromHomeScreen = NO;
    }

    return self;
}

- (void)composeTweet
{
    TweetDraft * draft =
        [self.draftMgr tweetDraftForCredentials:self.service.credentials];

    NSString * text = draft ? draft.text : @"";
    [self composeTweetWithText:text];
}

- (void)composeTweetWithText:(NSString *)tweet
{
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    self.origTweetId = nil;
    self.origUsername = nil;

    [self.composeTweetViewController composeTweet:tweet
                                             from:service.credentials.username];
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
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    self.origTweetId = tweetId;
    self.origUsername = user;

    [self.composeTweetViewController composeTweet:text
                                             from:service.credentials.username
                                        inReplyTo:user];
}

- (void)composeDirectMessage
{
    DirectMessageDraft * draft =
        [self.draftMgr
        directMessageDraftFromHomeScreenForCredentials:service.credentials];
    NSAssert(!draft || draft.fromHomeScreen.boolValue, @"Found wrong draft.");

    fromHomeScreen = YES;
    self.origUsername = nil;
    self.origTweetId = nil;

    NSString * recipient = draft ? draft.recipient : @"";
    NSString * sender = service.credentials.username;
    NSString * text = draft ? draft.text : @"";

    // Present the view before calling 'composeDirectMessage:...' because
    // otherwise the view elements aren't wired up (they're nil).
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    [self.composeTweetViewController composeDirectMessage:text
                                                     from:sender
                                                       to:recipient];
}

- (void)composeDirectMessageTo:(NSString *)username
{
    DirectMessageDraft * draft =
        [self.draftMgr directMessageDraftForCredentials:self.service.credentials
                                              recipient:username];

    fromHomeScreen = NO;

    NSString * text = draft ? draft.text : @"";
    [self composeDirectMessageTo:username withText:text];
}

- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)text
{
    self.origUsername = nil;
    self.origTweetId = nil;

    fromHomeScreen = NO;

    // Present the view before calling 'composeDirectMessage:...' because
    // otherwise the view elements aren't wired up (they're nil).
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    NSString * sender = service.credentials.username;
    [self.composeTweetViewController composeDirectMessage:text
                                                     from:sender
                                                       to:username];
}

#pragma mark Credentials notifications

- (void)setCredentials:(TwitterCredentials *)credentials
{
    self.service.credentials = credentials;
}

- (void)credentialsSetChanged:(TwitterCredentials *)credentials
                        added:(NSNumber *)added
{
    if (![added boolValue]) {
        // remove all drafts for the deleted account
        NSError * error = nil;
        [self.draftMgr deleteTweetDraftForCredentials:credentials error:&error];

        if (error) {
            NSLog(@"Failed to delete tweet drafts for deleted credentials: "
                "'%@', '%@'.", credentials, error);
            error = nil;
        }

        [self.draftMgr deleteAllDirectMessageDraftsForCredentials:credentials
                                                            error:&error];
        if (error)
            NSLog(@"Failed to delete direct message drafts for deleted "
                "credentials: '%@', '%@'.", credentials, error);
    }
}

#pragma mark LogInDisplayMgrDelegate implementation

- (void)logInCompleted
{
    [self promptForPhotoSource:
        self.composeTweetViewController.modalViewController];
}

- (void)logInCancelled
{
}

#pragma mark ComposeTweetViewControllerDelegate implementation

- (void)userWantsToSendTweet:(NSString *)text
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    if (self.origTweetId) {  // sending a public reply
        [self.delegate userIsReplyingToTweet:self.origTweetId
                                    fromUser:self.origUsername
                                    withText:text];
        [self.service sendTweet:text inReplyTo:self.origTweetId];
    } else {
        [self.delegate userIsSendingTweet:text];
        [self.service sendTweet:text];
    }

    NSError * error = nil;
    [self.draftMgr deleteTweetDraftForCredentials:self.service.credentials
                                            error:&error];

    if (error)
        NSLog(@"Failed to delete tweet drafts: '%@', '%@'.", error,
              error.userInfo);
}

- (void)userWantsToSendDirectMessage:(NSString *)text
                         toRecipient:(NSString *)recipient
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    [self.delegate userIsSendingDirectMessage:text to:recipient];
    [self.service sendDirectMessage:text to:recipient];

    TwitterCredentials * credentials = self.service.credentials;
    NSError * error = nil;
    if (fromHomeScreen)
        [self.draftMgr
            deleteDirectMessageDraftFromHomeScreenForCredentials:credentials
                                                           error:&error];
    else
        [self.draftMgr
            deleteDirectMessageDraftForRecipient:recipient
                                     credentials:credentials
                                           error:&error];

    if (error)
        NSLog(@"Failed to delete tweet drafts: '%@', '%@'.", error,
              error.userInfo);
}

- (void)userDidSaveTweetDraft:(NSString *)text
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    NSError * error = nil;
    [self.draftMgr saveTweetDraft:text
                      credentials:self.service.credentials
                            error:&error];

    if (error) {
        NSLog(@"Failed to save tweet drafts: '%@', '%@'.", error,
            error.userInfo);
        NSString * title =
            NSLocalizedString(@"compose.draft.save.failed.title", @"");
        NSString * message =
            [error.userInfo valueForKeyPath:@"reason"] ?
            [error.userInfo valueForKeyPath:@"reason"] :
            error.localizedDescription;
        [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    }

    [self.delegate userDidCancelComposingTweet];
}

- (void)userDidSaveDirectMessageDraft:(NSString *)text
                          toRecipient:(NSString *)recipient
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    TwitterCredentials * credentials = self.service.credentials;
    NSError * error = nil;
    if (fromHomeScreen)
        [self.draftMgr saveDirectMessageDraftFromHomeScreen:text
                                                  recipient:recipient
                                                credentials:credentials
                                                      error:&error];
    else
        [self.draftMgr saveDirectMessageDraft:text
                                    recipient:recipient
                                  credentials:self.service.credentials
                                        error:&error];

    if (error) {
        NSLog(@"Failed to save tweet drafts: '%@', '%@'.", error,
            error.userInfo);
        NSString * title =
            NSLocalizedString(@"compose.draft.save.failed.title", @"");
        NSString * message =
            [error.userInfo valueForKeyPath:@"reason"] ?
            [error.userInfo valueForKeyPath:@"reason"] :
            error.localizedDescription;
        [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    }

    [self.delegate userDidCancelComposingTweet];
}

- (void)userDidCancelComposingTweet:(NSString *)text
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    NSError * error = nil;
    [self.draftMgr deleteTweetDraftForCredentials:self.service.credentials
                                            error:&error];

    [self.delegate userDidCancelComposingTweet];
}

- (void)userDidCancelComposingDirectMessage:(NSString *)text
                                toRecipient:(NSString *)recipient
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    TwitterCredentials * credentials = self.service.credentials;
    NSError * error = nil;

    if (fromHomeScreen)
        [self.draftMgr
            deleteDirectMessageDraftFromHomeScreenForCredentials:credentials
                                                           error:&error];
    else
        [self.draftMgr deleteDirectMessageDraftForRecipient:recipient
                                                credentials:credentials
                                                      error:&error];

    [self.delegate userDidCancelComposingTweet];
}

- (void)userWantsToSelectPhoto
{
    TwitterCredentials * credentials = self.service.credentials;
    if (credentials.twitPicCredentials == nil)
        [self.logInDisplayMgr logInForUser:credentials.username animated:YES];
    else
        [self promptForPhotoSource:self.composeTweetViewController];
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

    TwitPicCredentials * c = service.credentials.twitPicCredentials;
    NSAssert(c, @"Unexpected nil value for TwitPic credentials while uploading "
        "image.");
    [imageSender sendImage:image withCredentials:c];
    [self.composeTweetViewController displayActivityView];
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIViewController * controller =
        self.composeTweetViewController.modalViewController ?
        self.composeTweetViewController.modalViewController :
        self.composeTweetViewController;
    switch (buttonIndex) {
        case 0:  // camera
            [self displayImagePicker:UIImagePickerControllerSourceTypeCamera
                          controller:controller];
            break;
        case 1:  // library
            [self displayImagePicker:
                UIImagePickerControllerSourceTypePhotoLibrary
                          controller:controller];
            break;
    }

    [actionSheet autorelease];
}

#pragma mark UIImagePicker helper methods

- (void)promptForPhotoSource:(UIViewController *)controller
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
        [sheet showInView:controller.view];
    } else {
        if (cameraAvailable)
            source = camera;
        else
            source = photoLibrary;

        [self displayImagePicker:source controller:controller];
    }
}

- (void)displayImagePicker:(UIImagePickerControllerSourceType)source
                controller:(UIViewController *)controller
{
    UIImagePickerController * imagePicker =
        [[UIImagePickerController alloc] init];

    imagePicker.delegate = self;
    imagePicker.allowsImageEditing = YES;
    imagePicker.sourceType = source;

    [controller presentModalViewController:imagePicker animated:YES];
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

- (LogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr) {
        logInDisplayMgr = [[LogInDisplayMgr alloc]
            initWithRootViewController:self.composeTweetViewController
                  managedObjectContext:self.context];
        logInDisplayMgr.delegate = self;
        logInDisplayMgr.allowsCancel = YES;
    }

    return logInDisplayMgr;
}

- (TweetDraftMgr *)draftMgr
{
    if (!draftMgr)
        draftMgr =
            [[TweetDraftMgr alloc] initWithManagedObjectContext:self.context];

    return draftMgr;
}

@end
