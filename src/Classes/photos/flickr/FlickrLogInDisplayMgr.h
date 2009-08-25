//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServiceLogInDisplayMgr.h"
#import "ExplainFlickrAuthViewController.h"
#import "FlickrLogInViewController.h"
#import "ObjectiveFlickr.h"

@interface FlickrLogInDisplayMgr :
    PhotoServiceLogInDisplayMgr
    <ExplainFlickrAuthViewControllerDelegate, FlickrLogInViewControllerDelegate,
    OFFlickrAPIRequestDelegate>
{
    UINavigationController * explainNavigationController;
    ExplainFlickrAuthViewController * explainViewController;

    UINavigationController * flickrLogInNavigationController;
    FlickrLogInViewController * flickrLogInViewController;

    OFFlickrAPIContext * flickrContext;
    OFFlickrAPIRequest * getFrobRequest;
    OFFlickrAPIRequest * getTokenRequest;

    NSURL * flickrLogInUrl;
    NSString * frob;
}

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext;

@end
