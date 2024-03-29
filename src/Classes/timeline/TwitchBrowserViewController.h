//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TwitchBrowserViewControllerDelegate.h"

@interface TwitchBrowserViewController :
    UIViewController <UIWebViewDelegate, UIActionSheetDelegate,
    MFMailComposeViewControllerDelegate>
{
    IBOutlet UINavigationItem * navItem;
    IBOutlet UIToolbar * browserToolbar;
    IBOutlet UINavigationBar * browserNavBar;
    IBOutlet UIWebView * webView;
    IBOutlet UIBarButtonItem * backButton;
    IBOutlet UIBarButtonItem * forwardButton;
    IBOutlet UIBarButtonItem * haltButton;
    IBOutlet UILabel * titleLabel;
    IBOutlet UIActivityIndicatorView * activityIndicator;

    NSString * currentUrl;
    
    NSObject<TwitchBrowserViewControllerDelegate> * delegate;

    BOOL displayed;
    
    // This is set as soon as the interface starts to change, instead of after
    // it finishes animating
    UIInterfaceOrientation effectiveOrientation;
}

@property (nonatomic, copy) NSString * currentUrl;

@property (nonatomic, assign) NSObject<TwitchBrowserViewControllerDelegate> *
    delegate;

- (void)setUrl:(NSString *)url;
- (void)setUrl:(NSString *)url html:(NSString *)html;

- (NSString *)viewingUrl;
- (NSString *)viewingHtml;

- (IBAction)dismissView;
- (IBAction)moveBackAPage;
- (IBAction)moveForwardAPage;
- (IBAction)haltLoading;
- (IBAction)showActions;

- (void)openInSafari;
- (void)sendInEmail;
- (void)postInTweet;
- (void)readLater;

@end
