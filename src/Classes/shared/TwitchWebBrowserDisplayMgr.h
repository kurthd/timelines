//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitchBrowserViewController.h"
#import "ComposeTweetDisplayMgr.h"

@protocol TwitchWebBrowserDisplayMgrDelegate

- (void)readLater:(NSString *)url;

@end

@interface TwitchWebBrowserDisplayMgr :
    NSObject <TwitchBrowserViewControllerDelegate>
{
    id<TwitchWebBrowserDisplayMgrDelegate> delegate;

    TwitchBrowserViewController * browserController;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    UIViewController * hostViewController;
}

@property (nonatomic, assign) id<TwitchWebBrowserDisplayMgrDelegate> delegate;

@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) UIViewController * hostViewController;
@property (nonatomic, retain, readonly) TwitchBrowserViewController *
    browserController;

+ (TwitchWebBrowserDisplayMgr *)instance;
- (void)visitWebpage:(NSString *)webpageUrl;
- (void)visitWebpage:(NSString *)webpageUrl withHtml:(NSString *)html
    animated:(BOOL)animated;

- (NSString *)currentUrl;
- (NSString *)currentHtml;

@end
