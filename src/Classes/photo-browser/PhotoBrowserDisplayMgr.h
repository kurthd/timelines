//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoBrowser.h"
#import "ComposeTweetDisplayMgr.h"
#import "RemotePhoto.h"

@interface PhotoBrowserDisplayMgr : NSObject
{
    PhotoBrowser * photoBrowser;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    UIViewController * hostViewController;
}

@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) UIViewController * hostViewController;

+ (PhotoBrowserDisplayMgr *)instance;
- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto;

@end
