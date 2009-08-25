//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrLogInViewController.h"

@interface FlickrLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;

@property (nonatomic, retain) UIBarButtonItem * doneButton;
@property (nonatomic, retain) UIBarButtonItem * activityButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@end

@implementation FlickrLogInViewController

@synthesize delegate;
@synthesize webView;
@synthesize doneButton, activityButton, cancelButton;

- (void)dealloc
{
    self.delegate = nil;

    self.webView = nil;

    self.doneButton = nil;
    self.activityButton = nil;
    self.cancelButton = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<FlickrLogInViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"FlickrLogInView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"flickrloginview.title", @"");
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSURL * url = [self.delegate flickrLogInUrl];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark Button actions

- (IBAction)userDidFinish:(id)sender
{
    [self.delegate userDidAuthorizeFlickr];
}

- (IBAction)userDidCancel:(id)sender
{
    [self.delegate userDidCancelFlickrLogIn];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    [self.navigationItem setRightBarButtonItem:self.activityButton
                                      animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    [self.navigationItem setRightBarButtonItem:self.doneButton
                                      animated:YES];
}

#pragma mark Accessors

- (UIBarButtonItem *)activityButton
{
    if (!activityButton) {
        UIActivityIndicatorView * ai =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [ai startAnimating];
        activityButton = [[UIBarButtonItem alloc] initWithCustomView:ai];
        [ai release];
    }

    return activityButton;
}

@end
