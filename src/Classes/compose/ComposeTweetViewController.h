//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CurrentLocationView.h"

@protocol ComposeTweetViewControllerDelegate;

@interface ComposeTweetViewController :
    UIViewController <UIActionSheetDelegate, UITextFieldDelegate,
    CurrentLocationViewDelegate>
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UIView * portraitHeaderView;
    IBOutlet UILabel * portraitTitleLabel;
    IBOutlet UILabel * portraitAccountLabel;

    IBOutlet UITextView * textView;

    IBOutlet UIToolbar * toolbar;
    UIBarButtonItem * sendButton;
    UIBarButtonItem * cancelButton;

    IBOutlet UIBarButtonItem * shortenLinksButton;
    IBOutlet UIBarButtonItem * geoTagButton;
    IBOutlet UILabel * characterCountPortrait;
    IBOutlet UILabel * characterCountLandscape;

    BOOL hideRecipientView;
    IBOutlet UIView * recipientView;
    IBOutlet UILabel * recipientToLabel;
    IBOutlet UIImageView * recipientBackgroundView;
    IBOutlet UITextField * recipientTextField;
    IBOutlet UIButton * addRecipientButton;

    BOOL displayLocation;
    IBOutlet CurrentLocationView * locationView;
    BOOL displayLocationActivity;  // HACK
    NSString * locationViewText;

    /* Displaying activity while uploading media and shortening links. */

    BOOL displayingActivity;

    UIView * photoUploadView;
    UIProgressView * photoUploadProgressView;

    IBOutlet UIView * urlShorteningView;
    BOOL urlShorteningViewHasBeenInitialized;

    NSString * currentSender;
    NSString * textViewText;
    NSString * currentRecipient;

    BOOL viewNeedsInitialization;

    BOOL viewAlreadyDidLoad;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

@property (nonatomic, retain) UIBarButtonItem * sendButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, assign) BOOL displayLocation;
@property (nonatomic, assign) BOOL displayingActivity;

- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
              geotag:(BOOL)geotag;
- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
              geotag:(BOOL)geotag
           inReplyTo:(NSString *)recipient;

- (void)composeDirectMessage:(NSString *)text from:(NSString *)sender;
- (void)composeDirectMessage:(NSString *)text
                        from:(NSString *)sender
                          to:(NSString *)recipient;

- (void)setRecipient:(NSString *)recipient;

- (void)addTextToMessage:(NSString *)text;
- (void)replaceOccurrencesOfString:(NSString *)oldString
                        withString:(NSString *)newString;

- (void)displayPhotoUploadView;
- (void)updatePhotoUploadProgress:(CGFloat)uploadProgress;
- (void)hidePhotoUploadView;

- (void)displayUrlShorteningView;
- (void)hideUrlShorteningView;

- (void)displayLocationDescription:(BOOL)display animated:(BOOL)animated;
- (void)displayUpdatingLocationActivity:(BOOL)display;
- (void)updateLocationDescription:(NSString *)description;
- (void)displayUpdatingLocationError:(NSError *)error;

- (void)userDidSend;
- (void)userDidClose;
- (IBAction)chooseDirectMessageRecipient;
- (IBAction)promptToClearTweet;
- (IBAction)choosePhoto;
- (IBAction)shortenLinks;
- (IBAction)choosePerson;
- (IBAction)geotag;

@end


@protocol ComposeTweetViewControllerDelegate

- (void)userWantsToSendTweet:(NSString *)text;
- (void)userWantsToSendDirectMessage:(NSString *)text
                         toRecipient:(NSString *)recipient;

- (void)userDidSaveTweetDraft:(NSString *)text;
- (void)userDidSaveDirectMessageDraft:(NSString *)text
                          toRecipient:(NSString *)recipient;

- (void)userWantsToSelectDirectMessageRecipient;

- (void)userWantsToSelectPhoto;
- (void)userWantsToShortenUrls:(NSSet *)urls;
- (void)userWantsToSelectPerson;

- (void)userDidCancelPhotoUpload;
- (void)userDidCancelUrlShortening;

- (BOOL)clearCurrentDirectMessageDraftTo:(NSString *)recipient;
- (BOOL)clearCurrentTweetDraft;

- (void)userDidTapGeotagButton;
- (void)showCurrentLocation;

- (void)closeView;

@end
