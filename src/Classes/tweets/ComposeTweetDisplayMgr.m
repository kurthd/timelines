//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>  // for kUTTypeMovie
#import "ComposeTweetDisplayMgr.h"
#import "ComposeTweetViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "TweetDraft.h"
#import "DirectMessageDraft.h"
#import "TweetDraftMgr.h"
#import "TwitterCredentials+PhotoServiceAdditions.h"
#import "PhotoService+ServiceAdditions.h"
#import "AccountSettings.h"
#import "NSString+ConvenienceMethods.h"
#import "UIColor+TwitchColors.h"
#import "AsynchronousNetworkFetcher.h"
#import "InfoPlistConfigReader.h"
#import "RegexKitLite.h"
#import "ErrorState.h"

@interface ComposeTweetDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, readonly) UIViewController * navController;
@property (nonatomic, retain) ComposeTweetViewController *
    composeTweetViewController;

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsUpdatePublisher;
@property (nonatomic, retain) CredentialsSetChangedPublisher *
    credentialsSetChangedPublisher;

@property (nonatomic, retain) AddPhotoServiceDisplayMgr *
    addPhotoServiceDisplayMgr;

@property (nonatomic, copy) NSString * origUsername;
@property (nonatomic, copy) NSString * origTweetId;

@property (nonatomic, retain) TweetDraftMgr * draftMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) NSMutableArray * attachedPhotos;
@property (nonatomic, retain) NSMutableArray * attachedVideos;

@property (nonatomic, readonly) UIView * linkShorteningView;

- (void)promptForPhotoSource:(UIViewController *)controller;
- (void)displayImagePicker:(UIImagePickerControllerSourceType)source
                controller:(UIViewController *)controller;

+ (NSString *)removeStrings:(NSArray *)strings fromString:(NSString *)str;

- (void)updateMediaTitleFromTweet:(Tweet *)tweet;
- (void)updateMediaTitleFromDirectMessage:(DirectMessage *)dm;
- (void)updateMediaTitleFromTweetText:(NSString *)text;

- (void)startShorteningLink:(NSString *)link;
- (void)abortShorteningLink;
- (void)showShorteningLinkView;
- (void)removeShorteningLinkView;

@end

@implementation ComposeTweetDisplayMgr

@synthesize rootViewController, composeTweetViewController;
@synthesize service;
@synthesize credentialsUpdatePublisher, credentialsSetChangedPublisher;
@synthesize logInDisplayMgr, context;
@synthesize delegate;
@synthesize origUsername, origTweetId;
@synthesize draftMgr;
@synthesize addPhotoServiceDisplayMgr;
@synthesize attachedPhotos, attachedVideos;

- (void)dealloc
{
    self.delegate = nil;
    self.rootViewController = nil;
    [navController release];
    self.composeTweetViewController = nil;
    self.service = nil;
    self.credentialsUpdatePublisher = nil;
    self.credentialsSetChangedPublisher = nil;
    self.addPhotoServiceDisplayMgr = nil;
    self.origUsername = nil;
    self.origTweetId = nil;
    self.draftMgr = nil;
    self.attachedPhotos = nil;
    self.attachedVideos = nil;
    [linkShorteningView release];
    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                         context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.service = aService;
        self.service.delegate = self;

        self.context = aContext;

        credentialsUpdatePublisher = [[CredentialsActivatedPublisher alloc]
            initWithListener:self action:@selector(setCredentials:)];
        credentialsSetChangedPublisher =
            [[CredentialsSetChangedPublisher alloc]
                initWithListener:self
                          action:@selector(credentialsSetChanged:added:)];

        fromHomeScreen = NO;

        self.attachedPhotos = [NSMutableArray array];
        self.attachedVideos = [NSMutableArray array];
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
    [self.rootViewController presentModalViewController:self.navController
        animated:YES];

    self.origTweetId = nil;
    self.origUsername = nil;

    [self.composeTweetViewController composeTweet:tweet
                                             from:service.credentials.username];
}

- (void)composeTweetWithLink:(NSString *)link
{
    [self.rootViewController presentModalViewController:self.navController
        animated:YES];

    self.origTweetId = nil;
    self.origUsername = nil;

    [self.composeTweetViewController composeTweet:link
        from:service.credentials.username];

    if (![link isMatchedByRegex:@".*bit\\.ly/.*"])
        [self startShorteningLink:link];
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
        presentModalViewController:self.navController
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
        presentModalViewController:self.navController
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
        presentModalViewController:self.navController
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
    PhotoServiceCredentials * photoCredentials =
        [credentials defaultPhotoServiceCredentials];
    if (photoCredentials)
        [self promptForPhotoSource:self.composeTweetViewController];
    else
        [self.addPhotoServiceDisplayMgr addPhotoService:credentials];
}

#pragma mark TwitterServiceDelegate implementation

- (void)tweetSentSuccessfully:(Tweet *)tweet
{
    if (self.attachedPhotos.count > 0 || self.attachedVideos.count > 0) {
        [self updateMediaTitleFromTweet:tweet];

        self.attachedPhotos = [NSMutableArray array];
        self.attachedVideos = [NSMutableArray array];
    }

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
    if (self.attachedPhotos.count > 0 || self.attachedVideos.count > 0) {
        [self updateMediaTitleFromTweet:tweet];

        self.attachedPhotos = [NSMutableArray array];
        self.attachedVideos = [NSMutableArray array];
    }

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
    if (self.attachedPhotos.count > 0 || self.attachedVideos.count > 0) {
        [self updateMediaTitleFromDirectMessage:dm];

        self.attachedPhotos = [NSMutableArray array];
        self.attachedVideos = [NSMutableArray array];
    }

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

#pragma mark PhotoServiceDelegate implementation

- (void)service:(PhotoService *)photoService didPostImageToUrl:(NSString *)url
{
    NSLog(@"Successfully posted image to URL: '%@'.", url);

    [self.composeTweetViewController hideActivityView];
    [self.composeTweetViewController addTextToMessage:url];

    [self.attachedPhotos addObject:url];

    [photoService autorelease];
}

- (void)service:(PhotoService *)photoService didPostVideoToUrl:(NSString *)url
{
    NSLog(@"Successfully posted video to URL: '%@'.", url);

    [self.composeTweetViewController hideActivityView];
    [self.composeTweetViewController addTextToMessage:url];

    [self.attachedVideos addObject:url];

    [photoService autorelease];
}

- (void)service:(PhotoService *)photoService failedToPostImage:(NSError *)error
{
    NSLog(@"Failed to post image to URL: '%@'.", error);

    NSString * title = NSLocalizedString(@"imageupload.failed.title", @"");

    [[UIAlertView simpleAlertViewWithTitle:title
                                   message:error.localizedDescription] show];

    [self.composeTweetViewController hideActivityView];

    [photoService autorelease];
}

- (void)service:(PhotoService *)photoService failedToPostVideo:(NSError *)error
{
    NSLog(@"Failed to post video to URL: '%@'.", error);

    NSString * title = NSLocalizedString(@"videoupload.failed.title", @"");

    [[UIAlertView simpleAlertViewWithTitle:title
                                   message:error.localizedDescription] show];

    [self.composeTweetViewController hideActivityView];

    [photoService autorelease];
}

- (void)serviceDidUpdatePhotoTitle:(PhotoService *)photoService
{
    NSLog(@"Successfully updated photo title.");
    [photoService autorelease];
}

- (void)service:(PhotoService *)photoService
    failedToUpdatePhotoTitle:(NSError *)error
{
    NSLog(@"Failed to update photo title: %@", error);
    [photoService autorelease];
}

- (void)serviceDidUpdateVideoTitle:(PhotoService *)photoService
{
    NSLog(@"Successfully updated video title.");
    [photoService autorelease];
}

- (void)service:(PhotoService *)photoService
    failedToUpdateVideoTitle:(NSError *)error
{
    NSLog(@"Failed to update video title: %@", error);
    [photoService autorelease];
}

#pragma mark UIImagePickerControllerDelegate implementation

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *) kUTTypeMovie]) {
        NSURL * videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];

        PhotoServiceCredentials * c =
            [service.credentials defaultVideoServiceCredentials];
        NSString * serviceName = [c serviceName];
        NSLog(@"Uploading video to: '%@'.", serviceName);

        PhotoService * photoService =
            [[PhotoService photoServiceWithServiceName:serviceName] retain];
        photoService.delegate = self;

        [photoService sendVideoAtUrl:videoUrl withCredentials:c];
    } else if ([mediaType isEqualToString:(NSString *) kUTTypeImage]) {
        NSLog(@"Cropped image: %@.",
           [info objectForKey:UIImagePickerControllerEditedImage]);
        NSLog(@"Original image: %@.",
            [info objectForKey:UIImagePickerControllerOriginalImage]);

        UIImage * image =
            [info objectForKey:UIImagePickerControllerEditedImage];
        if (!image)
            image = [info objectForKey:UIImagePickerControllerOriginalImage];

        PhotoServiceCredentials * c =
            [service.credentials defaultPhotoServiceCredentials];
        NSString * serviceName = [c serviceName];
        NSLog(@"Uploading photo to: '%@'", serviceName);
        PhotoService * photoService =
            [[PhotoService photoServiceWithServiceName:serviceName] retain];
        photoService.delegate = self;
        [photoService sendImage:image withCredentials:c];
    }

    [self.composeTweetViewController displayActivityView];
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark AddPhotoServiceDisplayMgrDelegate implementation

- (void)photoServiceAdded:(PhotoServiceCredentials *)credentials
{
    // HACK: Just save the settings here. This code is adapted from the photo
    // services display mgr, and should be refactored to a common place.
    NSString * serviceName = [credentials serviceName];
    NSString * settingsKey = credentials.credentials.username;
    AccountSettings * settings =
        [AccountSettings settingsForKey:settingsKey];

    NSString * photoService = [settings photoServiceName];
    if (!photoService && [credentials supportsPhotos])
        [settings setPhotoServiceName:serviceName];

    NSString * videoService = [settings videoServiceName];
    if (!videoService && [credentials supportsVideo])
        [settings setVideoServiceName:serviceName];

    [AccountSettings setSettings:settings forKey:settingsKey];

    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(dismissSelector:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)addingPhotoServiceCancelled
{
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

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    if (!canceledLinkShortening) {
        NSString * json =
            [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]
            autorelease];
        NSString * shortUrl = json; // TODO: parse
        [self.composeTweetViewController composeTweet:shortUrl
            from:service.credentials.username];

        [self removeShorteningLinkView];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    if (!canceledLinkShortening) {
        NSString * title =
            NSLocalizedString(@"composetweet.shorteningerror", @"");
        [[ErrorState instance] displayErrorWithTitle:title error:error];
        [self removeShorteningLinkView];
    }
}

#pragma mark UIImagePicker helper methods

- (void)promptForPhotoSource:(UIViewController *)controller
{
    // to help with readability
    UIImagePickerControllerSourceType photoLibrary =
        UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerControllerSourceType camera =
        UIImagePickerControllerSourceTypeCamera;

    BOOL libraryAvailable =
        [UIImagePickerController isSourceTypeAvailable:photoLibrary];
    BOOL cameraAvailable =
        [UIImagePickerController isSourceTypeAvailable:camera];
    BOOL videoAvailable =
        cameraAvailable &&
        [[UIImagePickerController
        availableMediaTypesForSourceType:camera]
        containsObject:(NSString *) kUTTypeMovie];

    // make sure the user has added a video service
    videoAvailable =
        videoAvailable && [service.credentials defaultVideoServiceCredentials];

    if (cameraAvailable && libraryAvailable) {
        NSString * cancelButton =
            NSLocalizedString(@"imagepicker.choose.cancel", @"");
        NSString * cameraButton =
            videoAvailable ?
            NSLocalizedString(@"imagepicker.choose.camerawithvideo", @"") :
            NSLocalizedString(@"imagepicker.choose.camera", @"");
        NSString * photosButton =
            videoAvailable ?
            NSLocalizedString(@"imagepicker.choose.photoswithvideo", @"") :
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
        UIImagePickerControllerSourceType source;
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
    imagePicker.allowsImageEditing = NO;
    imagePicker.sourceType = source;

    NSMutableArray * mediaTypes =
        [NSMutableArray arrayWithObject:(NSString *) kUTTypeImage];
    NSArray * availableMedaTypes =
        [UIImagePickerController availableMediaTypesForSourceType:source];
    BOOL videoSupportedOnDevice =
        [availableMedaTypes containsObject:(NSString *) kUTTypeMovie];
    BOOL videoServiceInstalled =
        [service.credentials defaultVideoServiceCredentials] != nil;
    if (videoSupportedOnDevice && videoServiceInstalled)
        [mediaTypes addObject:(NSString *) kUTTypeMovie];
    imagePicker.mediaTypes = mediaTypes;

    [controller presentModalViewController:imagePicker animated:YES];
    [imagePicker release];
}

// HACK: Dismissing the modal view causes the app to crash. Putting it on a
// timer fixes the problem.
- (void)dismissSelector:(NSTimer *)timer
{
    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];

    [self performSelector:@selector(promptForPhotoSource:)
               withObject:self.composeTweetViewController
               afterDelay:0.5];
}

#pragma mark Private implementation

+ (NSString *)removeStrings:(NSArray *)strings fromString:(NSString *)str
{
    NSMutableString * s = [[str mutableCopy] autorelease];
    for (NSString * string in strings) {
        NSRange r = NSMakeRange(0, s.length);
        [s replaceOccurrencesOfString:string withString:@"" options:0 range:r];
    }

    return s;
}

- (void)updateMediaTitleFromTweet:(Tweet *)tweet
{
    [self updateMediaTitleFromTweetText:tweet.text];
}

- (void)updateMediaTitleFromDirectMessage:(DirectMessage *)dm
{
    [self updateMediaTitleFromTweetText:dm.text];
}

- (void)updateMediaTitleFromTweetText:(NSString *)text
{
    NSString * title = [[self class] removeStrings:self.attachedPhotos
                                        fromString:text];
    title = [[self class] removeStrings:self.attachedVideos fromString:title];

    if (self.attachedPhotos.count > 0) {
        PhotoServiceCredentials * photoCredentials =
            [service.credentials defaultPhotoServiceCredentials];
        NSString * serviceName = [photoCredentials serviceName];

        PhotoService * photoService =
            [[PhotoService photoServiceWithServiceName:serviceName] retain];
        photoService.delegate = self;

        for (NSString * photoUrl in self.attachedPhotos)
            if ([text containsString:photoUrl])
                [photoService setTitle:title forPhotoWithUrl:photoUrl
                    credentials:photoCredentials];
    }

    if (self.attachedVideos.count > 0) {
        PhotoServiceCredentials * photoCredentials =
            [service.credentials defaultVideoServiceCredentials];
        NSString * serviceName = [photoCredentials serviceName];

        PhotoService * photoService =
            [[PhotoService photoServiceWithServiceName:serviceName] retain];
        photoService.delegate = self;

        for (NSString * videoUrl in self.attachedVideos)
            if ([text containsString:videoUrl])
                [photoService setTitle:title forVideoWithUrl:videoUrl
                    credentials:photoCredentials];
    }
}

#pragma mark Accessors

- (ComposeTweetViewController *)composeTweetViewController
{
    if (!composeTweetViewController) {
        composeTweetViewController = [[ComposeTweetViewController alloc]
            initWithNibName:@"ComposeTweetView" bundle:nil];
        composeTweetViewController.delegate = self;
        
        NSString * cancelButtonText =
            NSLocalizedString(@"composetweet.navigationitem.cancel", @"");
        UIBarButtonItem * cancelButton =
            [[[UIBarButtonItem alloc]
            initWithTitle:cancelButtonText style:UIBarButtonItemStyleBordered
            target:composeTweetViewController action:@selector(userDidCancel)]
            autorelease];
        composeTweetViewController.navigationItem.leftBarButtonItem =
            cancelButton;
        composeTweetViewController.cancelButton = cancelButton;

        NSString * sendButtonText =
            NSLocalizedString(@"composetweet.navigationitem.send", @"");
        UIBarButtonItem * sendButton =
            [[[UIBarButtonItem alloc]
            initWithTitle:sendButtonText style:UIBarButtonItemStyleBordered
            target:composeTweetViewController action:@selector(userDidSave)]
            autorelease];
        composeTweetViewController.navigationItem.rightBarButtonItem =
            sendButton;
            
        composeTweetViewController.navigationItem.title =
            NSLocalizedString(@"composetweet.navigationitem.title", @"");
        composeTweetViewController.sendButton = sendButton;
    }

    return composeTweetViewController;
}

- (LogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr) {
        logInDisplayMgr = [[LogInDisplayMgr alloc]
            initWithRootViewController:self.navController
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

- (AddPhotoServiceDisplayMgr *)addPhotoServiceDisplayMgr
{
    if (!addPhotoServiceDisplayMgr) {
        addPhotoServiceDisplayMgr =
            [[AddPhotoServiceDisplayMgr alloc] initWithContext:context];
        [addPhotoServiceDisplayMgr
            displayModally:self.composeTweetViewController];
        [addPhotoServiceDisplayMgr selectorAllowsCancel:YES];
        addPhotoServiceDisplayMgr.delegate = self;
    }

    return addPhotoServiceDisplayMgr;
}

- (void)startShorteningLink:(NSString *)link
{
    canceledLinkShortening = NO;

    NSString * version =
        [[InfoPlistConfigReader reader] valueForKey:@"BitlyVersion"];
    NSString * username =
        [[InfoPlistConfigReader reader] valueForKey:@"BitlyUsername"];
    NSString * apiKey =
        [[InfoPlistConfigReader reader] valueForKey:@"BitlyApiKey"];
    NSString * urlAsString =
        [NSString stringWithFormat:
        @"http://api.bit.ly/shorten?version=%@&longUrl=%@&login=%@&apiKey=%@",
        version, link, username, apiKey];
    NSLog(@"Link shortening request: %@", urlAsString);
    NSURL * url = [NSURL URLWithString:urlAsString];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];

    self.composeTweetViewController.displayingActivity = YES;
    [self showShorteningLinkView];
}

- (void)abortShorteningLink
{
    canceledLinkShortening = YES;
    [self removeShorteningLinkView];
}

- (void)removeShorteningLinkView
{
    [self.linkShorteningView performSelector:@selector(removeFromSuperview)
        withObject:nil afterDelay:0.5];

    self.linkShorteningView.alpha = 1.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.linkShorteningView cache:YES];

    self.linkShorteningView.alpha = 0.0;

    [UIView commitAnimations];

    self.composeTweetViewController.displayingActivity = NO;
}

- (void)showShorteningLinkView
{
    [self.navController.view.superview.superview
        addSubview:self.linkShorteningView];
    self.linkShorteningView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.linkShorteningView cache:YES];

    self.linkShorteningView.alpha = 1.0;

    [UIView commitAnimations];
}

- (UIViewController *)navController
{
    if (!navController)
        navController =
            [[UINavigationController alloc]
            initWithRootViewController:self.composeTweetViewController];

    return navController;
}

- (UIView *)linkShorteningView
{
    if (!linkShorteningView) {
        CGRect darkTransparentViewFrame = CGRectMake(0, 0, 320, 460);
        UIView * darkTransparentView =
            [[[UIView alloc] initWithFrame:darkTransparentViewFrame]
            autorelease];
        darkTransparentView.backgroundColor = [UIColor blackColor];
        darkTransparentView.alpha = 0.9;

        UIActivityIndicatorView * activityIndicator =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]
            autorelease];
        activityIndicator.frame = CGRectMake(50, 87, 37, 37);
        [activityIndicator startAnimating];
        
        CGRect shorteningLabelFrame =
            CGRectMake(
            activityIndicator.frame.origin.x +
            activityIndicator.frame.size.width + 12,
            87,
            200,
            37);
        UILabel * shorteningLabel =
            [[[UILabel alloc] initWithFrame:shorteningLabelFrame] autorelease];
        shorteningLabel.text =
            NSLocalizedString(@"composetweet.shorteninglink", @"");
        shorteningLabel.backgroundColor = [UIColor clearColor];
        shorteningLabel.textColor = [UIColor whiteColor];
        shorteningLabel.font = [UIFont boldSystemFontOfSize:20];
        shorteningLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        shorteningLabel.shadowColor = [UIColor blackColor];

        static const NSInteger BUTTON_WIDTH = 134;
        CGRect buttonFrame =
            CGRectMake((320 - BUTTON_WIDTH) / 2, 146, BUTTON_WIDTH, 46);
        UIButton * cancelButton =
            [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
        NSString * cancelButtonTitle =
            NSLocalizedString(@"composetweet.cancelshortening", @"");
        [cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        UIImage * normalImage =
            [[UIImage imageNamed:@"CancelButton.png"]
            stretchableImageWithLeftCapWidth:13.0 topCapHeight:0.0];
        [cancelButton setBackgroundImage:normalImage
            forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [cancelButton setTitleColor:[UIColor whiteColor]
            forState:UIControlStateNormal];
        [cancelButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateHighlighted];
        [cancelButton setTitleShadowColor:[UIColor twitchDarkGrayColor]
            forState:UIControlStateNormal];
        cancelButton.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
        [cancelButton addTarget:self action:@selector(abortShorteningLink)
            forControlEvents:UIControlEventTouchUpInside];

        CGRect linkShorteningViewFrame = CGRectMake(0, 0, 320, 460);
        linkShorteningView =
            [[UIView alloc] initWithFrame:linkShorteningViewFrame];
        [linkShorteningView addSubview:darkTransparentView];
        [linkShorteningView addSubview:activityIndicator];
        [linkShorteningView addSubview:shorteningLabel];
        [linkShorteningView addSubview:cancelButton];
    }

    return linkShorteningView;
}

@end
