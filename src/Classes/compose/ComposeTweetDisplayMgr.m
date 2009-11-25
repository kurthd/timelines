//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetDisplayMgr.h"
#import "TwitbitShared.h"
#import <MobileCoreServices/MobileCoreServices.h>  // for kUTTypeMovie

@interface ComposeTweetDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UIViewController * navController;
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
@property (nonatomic, copy) NSNumber * origTweetId;

@property (nonatomic, retain) TweetDraftMgr * draftMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) PhotoService * photoService;

@property (nonatomic, retain) NSMutableArray * attachedPhotos;
@property (nonatomic, retain) NSMutableArray * attachedVideos;

@property (nonatomic, retain) BitlyUrlShorteningService *
    urlShorteningService;
@property (nonatomic, retain) NSMutableSet * urlsToShorten;

@property (nonatomic, retain) UIPersonSelector * personSelector;

@property (nonatomic, retain) Geolocator * geolocator;

- (void)promptForPhotoSource:(UIViewController *)controller;
- (void)displayImagePicker:(UIImagePickerControllerSourceType)source
                controller:(UIViewController *)controller;

+ (NSString *)removeStrings:(NSArray *)strings fromString:(NSString *)str;

- (void)updateMediaTitleFromTweet:(Tweet *)tweet;
- (void)updateMediaTitleFromDirectMessage:(DirectMessage *)dm;
- (void)updateMediaTitleFromTweetText:(NSString *)text;

- (void)startUpdatingLocation;
- (void)resetLocationState;

@end

@implementation ComposeTweetDisplayMgr

@synthesize rootViewController, navController, composeTweetViewController;
@synthesize service;
@synthesize credentialsUpdatePublisher, credentialsSetChangedPublisher;
@synthesize logInDisplayMgr, context;
@synthesize delegate;
@synthesize origUsername, origTweetId;
@synthesize draftMgr;
@synthesize addPhotoServiceDisplayMgr;
@synthesize attachedPhotos, attachedVideos;
@synthesize photoService;
@synthesize urlShorteningService, urlsToShorten;
@synthesize personSelector;
@synthesize composingTweet, directMessageRecipient;
@synthesize geolocator;

- (void)dealloc
{
    self.delegate = nil;
    self.rootViewController = nil;
    self.navController = nil;
    self.composeTweetViewController = nil;
    self.service = nil;
    self.credentialsUpdatePublisher = nil;
    self.credentialsSetChangedPublisher = nil;
    self.addPhotoServiceDisplayMgr = nil;
    self.origUsername = nil;
    self.origTweetId = nil;
    self.draftMgr = nil;
    self.photoService = nil;
    self.attachedPhotos = nil;
    self.attachedVideos = nil;
    self.urlShorteningService = nil;
    self.urlsToShorten = nil;
    self.personSelector = nil;
    self.geolocator = nil;

    if (lastCoordinate)
        free(lastCoordinate);

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

        self.urlsToShorten = [NSMutableSet set];
    }

    return self;
}

- (void)composeTweetAnimated:(BOOL)animated
{
    TweetDraft * draft =
        [self.draftMgr tweetDraftForCredentials:self.service.credentials];

    NSString * text = draft ? draft.text : @"";
    if (draft.inReplyToTweetId && draft.inReplyToUsername)
        [self composeReplyToTweet:draft.inReplyToTweetId
                         fromUser:draft.inReplyToUsername
                         withText:text];
    else
        [self composeTweetWithText:text animated:animated];
}

- (void)composeTweetWithText:(NSString *)tweet animated:(BOOL)animated
{
    composingTweet = YES;
    self.origTweetId = nil;
    self.origUsername = nil;

    [self.composeTweetViewController composeTweet:tweet
                                             from:service.credentials.username];
    [self.rootViewController presentModalViewController:self.navController
                                               animated:animated];

    [self startUpdatingLocation];
}

- (void)composeReplyToTweet:(NSNumber *)tweetId
                   fromUser:(NSString *)user
{
    self.origTweetId = tweetId;
    self.origUsername = user;

    NSString * tweetText = nil;

    // See if we're resuming a saved reply
    TweetDraft * draft =
        [self.draftMgr tweetDraftForCredentials:self.service.credentials];
    if ([draft.inReplyToTweetId isEqual:tweetId])
        tweetText = draft.text;
    else
        tweetText = [NSString stringWithFormat:@"@%@ ", user];

    NSString * username = self.service.credentials.username;
    [self.composeTweetViewController composeTweet:tweetText
                                             from:username
                                        inReplyTo:user];
    [self.rootViewController presentModalViewController:self.navController
                                               animated:YES];

    [self startUpdatingLocation];
}

- (void)composeReplyToTweet:(NSNumber *)tweetId
                   fromUser:(NSString *)user
                   withText:(NSString *)text
{
    /*
     * Ignore any drafts and accept the text as given.
     */

    self.origTweetId = tweetId;
    self.origUsername = user;

    [self.composeTweetViewController composeTweet:text
                                             from:service.credentials.username
                                        inReplyTo:user];

    [self.rootViewController presentModalViewController:self.navController
                                               animated:YES];

    [self startUpdatingLocation];
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

    [self.composeTweetViewController composeDirectMessage:text
                                                     from:sender
                                                       to:recipient];

    // Present the view before calling 'composeDirectMessage:...' because
    // otherwise the view elements aren't wired up (they're nil).
    [self.rootViewController presentModalViewController:self.navController
                                               animated:YES];
}

- (void)composeDirectMessageTo:(NSString *)username animated:(BOOL)animated
{
    DirectMessageDraft * draft =
        [self.draftMgr directMessageDraftForCredentials:self.service.credentials
                                              recipient:username];

    fromHomeScreen = NO;

    NSString * text = draft ? draft.text : @"";
    [self composeDirectMessageTo:username withText:text animated:animated];
}

- (void)composeDirectMessageTo:(NSString *)username
                      withText:(NSString *)text
                      animated:(BOOL)animated
{
    self.directMessageRecipient = username;
    self.origUsername = nil;
    self.origTweetId = nil;

    fromHomeScreen = NO;

    NSString * sender = service.credentials.username;
    [self.composeTweetViewController composeDirectMessage:text
                                                     from:sender
                                                       to:username];
    
    // Present the view before calling 'composeDirectMessage:...' because
    // otherwise the view elements aren't wired up (they're nil).
    [self.rootViewController presentModalViewController:self.navController
                                               animated:animated];
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
    composingTweet = NO;
    [self.rootViewController dismissModalViewControllerAnimated:YES];

    if (self.origTweetId) {  // sending a public reply
        [self.delegate userIsReplyingToTweet:self.origTweetId
                                    fromUser:self.origUsername
                                    withText:text];

        if (lastCoordinate)
            [self.service sendTweet:text
                         coordinate:*lastCoordinate
                          inReplyTo:self.origTweetId];
        else
            [self.service sendTweet:text inReplyTo:self.origTweetId];
    } else {
        [self.delegate userIsSendingTweet:text];

        if (lastCoordinate)
            [self.service sendTweet:text coordinate:*lastCoordinate];
        else
            [self.service sendTweet:text];
    }

    [self resetLocationState];

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
    self.directMessageRecipient = nil;

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
    if (text) {
        NSError * error = nil;
        if (self.origTweetId && self.origUsername)
            [self.draftMgr saveTweetDraft:text
                              credentials:self.service.credentials
                         inReplyToTweetId:self.origTweetId
                        inReplyToUsername:self.origUsername
                                    error:&error];
        else
            [self.draftMgr saveTweetDraft:text
                              credentials:self.service.credentials
                                    error:&error];

        if (error)
            NSLog(@"Failed to save tweet drafts: '%@', '%@'.", error,
                error.userInfo);
    }
}

- (void)userDidSaveDirectMessageDraft:(NSString *)text
                          toRecipient:(NSString *)recipient
{
    if (text && recipient) {
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

        if (error)
            NSLog(@"Failed to save direct message drafts: '%@', '%@'.", error,
                error.userInfo);
    }
}

- (void)userWantsToSelectDirectMessageRecipient
{
    selectingRecipient = YES;
    [self.personSelector
        promptToSelectUserModally:self.composeTweetViewController];
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

- (void)userWantsToShortenUrls:(NSSet *)urls
{
    NSLog(@"Shortening URLs: %@", urls);

    [self.urlsToShorten setSet:urls];
    [self.urlShorteningService shortenUrls:self.urlsToShorten];
    self.composeTweetViewController.displayingActivity = YES;
    [self.composeTweetViewController displayUrlShorteningView];
}

- (void)userWantsToSelectPerson
{
    selectingRecipient = NO;
    [self.personSelector
        promptToSelectUserModally:self.composeTweetViewController];
}

- (void)userDidCancelPhotoUpload
{
    if (self.photoService) {
        [self.photoService cancelUpload];
        [self.composeTweetViewController hidePhotoUploadView];

        self.photoService = nil;
    }
}

- (void)userDidCancelUrlShortening
{
    [self.urlsToShorten removeAllObjects];
    [self.composeTweetViewController hideUrlShorteningView];
}

- (BOOL)clearCurrentDirectMessageDraftTo:(NSString *)recipient;
{
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

    return error == nil;
}

- (BOOL)clearCurrentTweetDraft
{
    NSError * error = nil;
    [self.draftMgr deleteTweetDraftForCredentials:self.service.credentials
                                            error:&error];

    return error == nil;
}

- (void)closeView
{
    composingTweet = NO;
    self.directMessageRecipient = nil;
    [self resetLocationState];
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    [self.delegate userDidCancelComposingTweet];
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

- (void)tweet:(Tweet *)tweet sentInReplyTo:(NSNumber *)tweetId
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

- (void)failedToReplyToTweet:(NSNumber *)tweetId
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

- (void)service:(PhotoService *)aPhotoService didPostImageToUrl:(NSString *)url
{
    NSLog(@"Successfully posted image to URL: '%@'.", url);

    [self.composeTweetViewController hidePhotoUploadView];
    [self.composeTweetViewController addTextToMessage:url];

    [self.attachedPhotos addObject:url];

    [photoService autorelease];
    photoService = nil;
}

- (void)service:(PhotoService *)aPhotoService didPostVideoToUrl:(NSString *)url
{
    NSLog(@"Successfully posted video to URL: '%@'.", url);

    [self.composeTweetViewController hidePhotoUploadView];
    [self.composeTweetViewController addTextToMessage:url];

    [self.attachedVideos addObject:url];

    [photoService autorelease];
    photoService = nil;
}

- (void)service:(PhotoService *)aPhotoService failedToPostImage:(NSError *)error
{
    NSLog(@"Failed to post image to URL: '%@'.", error);

    NSString * title = NSLocalizedString(@"imageupload.failed.title", @"");
    NSString * savePhotoString =
        NSLocalizedString(@"imageupload.failed.save", @"");
    NSString * cancelTitle = NSLocalizedString(@"alert.dismiss", @"");

    UIAlertView * alertView =
        [[UIAlertView alloc]
          initWithTitle:title
                message:error.localizedDescription
               delegate:self
      cancelButtonTitle:cancelTitle
         otherButtonTitles:savePhotoString, nil];

    [alertView show];

    [self.composeTweetViewController hidePhotoUploadView];
}

- (void)service:(PhotoService *)aPhotoService failedToPostVideo:(NSError *)error
{
    NSLog(@"Failed to post video to URL: '%@'.", error);

    NSString * title = NSLocalizedString(@"videoupload.failed.title", @"");

    [[UIAlertView simpleAlertViewWithTitle:title
                                   message:error.localizedDescription] show];

    [self.composeTweetViewController hidePhotoUploadView];

    [photoService autorelease];
    photoService = nil;
}

- (void)service:(PhotoService *)service
    updateUploadProgress:(CGFloat)uploadProgress
{
    [self.composeTweetViewController updatePhotoUploadProgress:uploadProgress];
}

- (void)serviceDidUpdatePhotoTitle:(PhotoService *)aPhotoService
{
    NSLog(@"Successfully updated photo title.");
    [aPhotoService autorelease];
}

- (void)service:(PhotoService *)aPhotoService
    failedToUpdatePhotoTitle:(NSError *)error
{
    NSLog(@"Failed to update photo title: %@", error);
    [aPhotoService autorelease];
}

- (void)serviceDidUpdateVideoTitle:(PhotoService *)aPhotoService
{
    NSLog(@"Successfully updated video title.");
    [aPhotoService autorelease];
}

- (void)service:(PhotoService *)aPhotoService
    failedToUpdateVideoTitle:(NSError *)error
{
    NSLog(@"Failed to update video title: %@", error);
    [aPhotoService autorelease];
}

#pragma mark UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView
    didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Handles failed photo and video uploads
    if (buttonIndex == 1) {
        NSLog(@"Saving photo to album");
        UIImage * image = photoService.image;
        if (image)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }

    [alertView autorelease];

    [photoService autorelease];
    photoService = nil;
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

        self.photoService =
            [PhotoService photoServiceWithServiceName:serviceName];
        self.photoService.delegate = self;

        [self.photoService sendVideoAtUrl:videoUrl withCredentials:c];
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
        self.photoService =
            [PhotoService photoServiceWithServiceName:serviceName];
        self.photoService.delegate = self;

        UIImage * rotatedImage =
            [image imageByRotatingByOrientation:image.imageOrientation];
        [self.photoService sendImage:rotatedImage withCredentials:c];
    }

    [self.composeTweetViewController dismissModalViewControllerAnimated:YES];
    [self.composeTweetViewController updatePhotoUploadProgress:0.0];
    [self.composeTweetViewController displayPhotoUploadView];
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

    NSString * photoServiceName = [settings photoServiceName];
    if (!photoServiceName && [credentials supportsPhotos])
        [settings setPhotoServiceName:serviceName];

    NSString * videoService = [settings videoServiceName];
    if (!videoService && [credentials supportsVideo])
        [settings setVideoServiceName:serviceName];

    [AccountSettings setSettings:settings forKey:settingsKey];

    [NSTimer scheduledTimerWithTimeInterval:0.8
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

#pragma mark BitlyUrlShorteningServiceDelegate implementation

- (void)shorteningService:(BitlyUrlShorteningService *)service
        didShortenLongUrl:(NSString *)longUrl
               toShortUrl:(NSString *)shortUrl
{
    if ([self.urlsToShorten containsObject:longUrl]) {
        [self.composeTweetViewController replaceOccurrencesOfString:longUrl
                                                         withString:shortUrl];

        [self.urlsToShorten removeObject:longUrl];
        if (self.urlsToShorten.count == 0)
            [self.composeTweetViewController hideUrlShorteningView];
    } else
        NSLog(@"Don't know long URL: '%@'; ignoring.", longUrl);
}

- (void)shorteningService:(BitlyUrlShorteningService *)service
      didFailToShortenUrl:(NSString *)longUrl
                    error:(NSError *)error
{
    if ([self.urlsToShorten containsObject:longUrl]) {
        [self.urlsToShorten removeObject:longUrl];

        NSString * title =
            NSLocalizedString(@"composetweet.shorteningerror", @"");
        NSString * message = error.localizedDescription;
        [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

        if (self.urlsToShorten.count == 0)
            [self.composeTweetViewController hideUrlShorteningView];
    } else
        NSLog(@"Don't know long URL: '%@'; ignoring.", longUrl);
}

#pragma mark PersonSelectorDelegate implementation

- (void)userDidSelectPerson:(User *)user
{
    if (selectingRecipient)
        [self.composeTweetViewController setRecipient:user.username];
    else
        [self.composeTweetViewController
            addTextToMessage:[NSString stringWithFormat:@"@%@", user.username]];

    [personSelector autorelease];
    personSelector = nil;
}

- (void)userDidCancelPersonSelection
{
    [personSelector autorelease];
    personSelector = nil;
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

        if ([SettingsReader displayTheme] == kDisplayThemeDark)
            sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

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

#pragma mark GeolocatorDelegate implementation

- (void)geolocator:(Geolocator *)locator
 didUpdateLocation:(CLLocationCoordinate2D)crd
         placemark:(MKPlacemark *)placemark
{
    BOOL firstTime = !lastCoordinate;
    if (!lastCoordinate) {
        lastCoordinate =
            (CLLocationCoordinate2D *) malloc(sizeof(CLLocationCoordinate2D));
        memset(lastCoordinate, 0, sizeof(CLLocationCoordinate2D));
    }

    NSString * desc = [placemark humanReadableDescription];

    CLLocationDegrees lat = lastCoordinate->latitude;
    CLLocationDegrees lng = lastCoordinate->longitude;
    if (!firstTime && (crd.latitude == lat && crd.longitude == lng)) {
        NSLog(@"Final location: (%f, %f): %@.", lat, lng, desc);

        // we got the same location, so assume location has been determined
        [geolocator stopLocating];
        [geolocator autorelease];
        geolocator = nil;

        [self.composeTweetViewController displayUpdatingLocationActivity:NO];

        findingLocation = NO;
    } else {
        NSLog(@"Updating location to: (%f, %f): %@.", crd.latitude,
            crd.longitude, desc);

        NSString * fmt =
            NSLocalizedString(@"composetweet.location.formatstring", @"");

        NSString * fullDesc = [NSString stringWithFormat:fmt, desc];
        [self.composeTweetViewController updateLocationDescription:fullDesc];

        memcpy(lastCoordinate, &crd, sizeof(CLLocationCoordinate2D));

        findingLocation = YES;
        [self performSelector:@selector(processFindingLocationTimeout)
                   withObject:nil
                   afterDelay:4.0];
    }
}

- (void)geolocator:(Geolocator *)locator didFailWithError:(NSError *)error
{
    NSLog(@"Geolocator failed with error: %@", error);
}

- (void)processFindingLocationTimeout
{
    if (findingLocation) {
        NSLog(@"Finding location timed out.");
        [self.composeTweetViewController displayUpdatingLocationActivity:NO];
        findingLocation = NO;
    }
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

        for (NSString * photoUrl in self.attachedPhotos)
            if ([text containsString:photoUrl]) {
                PhotoService * aPhotoService =
                    [[PhotoService
                    photoServiceWithServiceName:serviceName] retain];
                aPhotoService.delegate = self;
                [aPhotoService setTitle:title forPhotoWithUrl:photoUrl
                    credentials:photoCredentials];
            }
    }

    if (self.attachedVideos.count > 0) {
        PhotoServiceCredentials * photoCredentials =
            [service.credentials defaultVideoServiceCredentials];
        NSString * serviceName = [photoCredentials serviceName];

        for (NSString * videoUrl in self.attachedVideos)
            if ([text containsString:videoUrl]) {
                PhotoService * aPhotoService =
                    [[PhotoService
                    photoServiceWithServiceName:serviceName] retain];
                aPhotoService.delegate = self;
                [aPhotoService setTitle:title forVideoWithUrl:videoUrl
                    credentials:photoCredentials];
            }
    }
}

- (void)startUpdatingLocation
{
    if (lastCoordinate) {
        free(lastCoordinate);
        lastCoordinate = NULL;
    }
    findingLocation = YES;
    [self.geolocator startLocating];
    [self.composeTweetViewController displayUpdatingLocationActivity:YES];
}

- (void)resetLocationState
{
    [self.geolocator stopLocating];
    self.geolocator = nil;
    if (lastCoordinate) {
        free(lastCoordinate);
        lastCoordinate = NULL;
    }
    findingLocation = NO;
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
            target:composeTweetViewController action:@selector(userDidClose)]
            autorelease];
        composeTweetViewController.navigationItem.leftBarButtonItem =
            cancelButton;
        composeTweetViewController.cancelButton = cancelButton;

        NSString * sendButtonText =
            NSLocalizedString(@"composetweet.navigationitem.send", @"");
        UIBarButtonItem * sendButton =
            [[[UIBarButtonItem alloc]
            initWithTitle:sendButtonText style:UIBarButtonItemStyleDone
            target:composeTweetViewController action:@selector(userDidSend)]
            autorelease];
        composeTweetViewController.navigationItem.rightBarButtonItem =
            sendButton;
        composeTweetViewController.sendButton = sendButton;

        composeTweetViewController.displayLocation = YES;
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

- (UIViewController *)navController
{
    if (!navController)
        navController =
            [[UINavigationController alloc]
            initWithRootViewController:self.composeTweetViewController];

    return navController;
}

- (UIPersonSelector *)personSelector
{
    if (!personSelector) {
        personSelector =
            [[UIPersonSelector alloc] initWithContext:self.context];
        personSelector.delegate = self;
    }

    return personSelector;
}

- (BitlyUrlShorteningService *)urlShorteningService
{
    if (!urlShorteningService) {
        urlShorteningService = [[BitlyUrlShorteningService alloc] init];
        urlShorteningService.delegate = self;
    }

    return urlShorteningService;
}

- (Geolocator *)geolocator
{
    if (!geolocator) {
        geolocator = [[Geolocator alloc] init];
        geolocator.delegate = self;
    }

    return geolocator;
}

@end
