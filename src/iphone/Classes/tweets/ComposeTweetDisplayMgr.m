//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeTweetDisplayMgr.h"
#import "ComposeTweetViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsUpdatePublisher.h"

@interface ComposeTweetDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) ComposeTweetViewController *
    composeTweetViewController;

@property (nonatomic, retain) TwitterService * service;

@property (nonatomic, retain) CredentialsUpdatePublisher *
    credentialsUpdatePublisher;

@end

@implementation ComposeTweetDisplayMgr

@synthesize rootViewController, composeTweetViewController;
@synthesize service, credentialsUpdatePublisher;

- (void)dealloc
{
    self.rootViewController = nil;
    self.composeTweetViewController = nil;
    self.service = nil;
    self.credentialsUpdatePublisher = nil;
    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.service = aService;
        self.service.delegate = self;

        credentialsUpdatePublisher = [[CredentialsUpdatePublisher alloc]
            initWithListener:self action:@selector(setCredentials:)];
    }

    return self;
}

- (void)composeTweet
{
    [self.rootViewController
        presentModalViewController:self.composeTweetViewController
                          animated:YES];

    [self.composeTweetViewController promptWithText:@""];
}

#pragma mark Credentials notifications

- (void)setCredentials:(TwitterCredentials *)credentials
{
    self.service.credentials = credentials;
}

#pragma mark ComposeTweetViewControllerDelegate implementation

- (void)userDidCancel
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)userDidSave:(NSString *)tweet
{
    [self.service sendTweet:tweet];
}

#pragma mark TwitterServiceDelegate implementation

- (void)tweetSentSuccessfully:(Tweet *)tweet
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)failedToSendTweet:(NSString *)tweet error:(NSError *)error
{
    NSString * title = NSLocalizedString(@"sendtweet.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];

    [self.composeTweetViewController promptWithText:tweet];
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
