//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ComposeTweetViewControllerDelegate;

@interface ComposeTweetViewController :
    UIViewController <UIActionSheetDelegate, UITextFieldDelegate>
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * titleLabel;
    IBOutlet UILabel * accountLabel;

    IBOutlet UITextView * textView;

    IBOutlet UIToolbar * toolbar;
    UIBarButtonItem * sendButton;
    UIBarButtonItem * cancelButton;

    IBOutlet UIBarButtonItem * shortenLinksButton;
    IBOutlet UILabel * characterCount;

    BOOL hideRecipientView;
    IBOutlet UIView * recipientView;
    IBOutlet UITextField * recipientTextField;

    /* Displaying activity while uploading media and shortening links. */

    BOOL displayingActivity;

    IBOutlet UIView * photoUploadView;
    IBOutlet UIProgressView * photoUploadProgressView;
    BOOL photoUploadViewHasBeenInitialized;

    IBOutlet UIView * urlShorteningView;
    BOOL urlShorteningViewHasBeenInitialized;

    NSString * currentSender;
    NSString * textViewText;
    NSString * currentRecipient;

    BOOL viewNeedsInitialization;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

@property (nonatomic, retain) UIBarButtonItem * sendButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, assign) BOOL displayingActivity;

- (void)composeTweet:(NSString *)text from:(NSString *)sender;
- (void)composeTweet:(NSString *)text
                from:(NSString *)sender
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

- (void)userDidSend;
- (void)userDidClose;
- (IBAction)chooseDirectMessageRecipient;
- (IBAction)promptToClearTweet;
- (IBAction)choosePhoto;
- (IBAction)shortenLinks;
- (IBAction)choosePerson;

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

- (void)closeView;

@end
