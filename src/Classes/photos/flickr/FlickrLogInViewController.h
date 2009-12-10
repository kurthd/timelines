//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlickrLogInViewControllerDelegate

- (NSURL *)flickrLogInUrl;

- (void)userDidCancelFlickrLogIn;
- (void)userDidAuthorizeFlickr;

@end

@interface FlickrLogInViewController : UIViewController
{
    id<FlickrLogInViewControllerDelegate> delegate;

    IBOutlet UIWebView * webView;

    IBOutlet UIBarButtonItem * doneButton;
    UIBarButtonItem * activityButton;
    IBOutlet UIBarButtonItem * cancelButton;
}

@property (nonatomic, assign) id<FlickrLogInViewControllerDelegate> delegate;

- (id)initWithDelegate:(id<FlickrLogInViewControllerDelegate>)aDelegate;

- (IBAction)userDidFinish:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
