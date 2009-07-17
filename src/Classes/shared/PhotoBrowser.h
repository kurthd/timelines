//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemotePhoto.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface PhotoBrowser :
    UIViewController <AsynchronousNetworkFetcherDelegate, UIActionSheetDelegate,
    MFMailComposeViewControllerDelegate>
{
    IBOutlet UIImageView * photoView;
    IBOutlet UINavigationItem * navItem;
    IBOutlet UIBarButtonItem * actionButton;
    IBOutlet UIBarButtonItem * forwardButton;
    IBOutlet UIBarButtonItem * backButton;
    IBOutlet UIView * loadingView;
    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIToolbar * toolbar;

    NSMutableArray * photoList;

    NSInteger selectedIndex;
    
    BOOL zoomed;
    BOOL notSingleTap;
    BOOL barsFaded;
    NSUInteger touchesCount;
    
    BOOL isDisplayed;
}

@property (nonatomic, readonly) NSMutableArray * photoList;

- (IBAction)done:(id)sender;
- (IBAction)showActions:(id)sender;

- (void)addRemotePhoto:(RemotePhoto *)remotePhoto;
- (void)setIndex:(NSUInteger)index;

- (void)goBack:(id)sender;
- (void)goForward:(id)sender;

@end
