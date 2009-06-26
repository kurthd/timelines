//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitchBrowserViewController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UINavigationItem * navItem;
    IBOutlet UIWebView * webView;
    IBOutlet UIBarButtonItem * backButton;
    IBOutlet UIBarButtonItem * forwardButton;
    IBOutlet UIBarButtonItem * haltButton;
    IBOutlet UILabel * titleLabel;
    IBOutlet UIActivityIndicatorView * activityIndicator;

    NSString * currentUrl;
}

@property (nonatomic, copy) NSString * currentUrl;

- (void)setUrl:(NSString *)url;

- (IBAction)dismissView;
- (IBAction)moveBackAPage;
- (IBAction)moveForwardAPage;
- (IBAction)haltLoading;
- (IBAction)openInSafari;

@end
