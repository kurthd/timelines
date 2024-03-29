//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemotePhoto.h"
#import "PhotoSource.h"
#import "PhotoSourceDelegate.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface PhotoBrowser :
    UIViewController <PhotoSourceDelegate, UIActionSheetDelegate,
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
    IBOutlet UIProgressView * progressView;

    NSMutableArray * photoList;

    NSInteger selectedIndex;

    BOOL zoomed;
    BOOL notSingleTap;
    BOOL barsFaded;
    BOOL sendingInEmail;
    NSUInteger touchesCount;

    BOOL isDisplayed;

    NSObject<PhotoSource> * photoSource;

    NSInteger previousOrientation;
}

@property (nonatomic, readonly) NSMutableArray * photoList;
@property (nonatomic, readonly) NSObject<PhotoSource> * photoSource;

- (IBAction)done:(id)sender;
- (IBAction)showActions:(id)sender;

- (void)addRemotePhoto:(RemotePhoto *)remotePhoto;
- (void)setIndex:(NSUInteger)index;

- (void)goBack:(id)sender;
- (void)goForward:(id)sender;

@end
