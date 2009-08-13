//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitchBrowserViewController.h"
#import "ComposeTweetDisplayMgr.h"

@interface TwitchWebBrowserDisplayMgr :
    NSObject <TwitchBrowserViewControllerDelegate>
{
    TwitchBrowserViewController * browserController;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    UIViewController * hostViewController;
}

@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) UIViewController * hostViewController;

+ (TwitchWebBrowserDisplayMgr *)instance;
- (void)visitWebpage:(NSString *)webpageUrl;

@end
