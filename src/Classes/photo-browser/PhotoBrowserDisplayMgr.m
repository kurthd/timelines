//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PhotoBrowserDisplayMgr.h"

@interface PhotoBrowserDisplayMgr ()

@property (readonly) PhotoBrowser * photoBrowser;

@end

@implementation PhotoBrowserDisplayMgr

@synthesize composeTweetDisplayMgr, hostViewController;

static PhotoBrowserDisplayMgr * gInstance = NULL;

+ (PhotoBrowserDisplayMgr *)instance
{
    @synchronized (self) {
        if (gInstance == NULL)
            gInstance = [[self alloc] init];
    }

    return gInstance;
}

- (void)dealloc
{
    [photoBrowser release];
    [composeTweetDisplayMgr release];
    [hostViewController release];
    [super dealloc];
}

- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto
{
    NSLog(@"Showing photo: %@", remotePhoto);

    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent
        animated:YES];

    [self.hostViewController presentModalViewController:self.photoBrowser
        animated:YES];
    [self.photoBrowser addRemotePhoto:remotePhoto];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

- (PhotoBrowser *)photoBrowser
{
    if (!photoBrowser) {
        photoBrowser =
            [[PhotoBrowser alloc]
            initWithNibName:@"PhotoBrowserView" bundle:nil];
    }

    return photoBrowser;
}

@end
