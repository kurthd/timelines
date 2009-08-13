//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchWebBrowserDisplayMgr.h"

@interface TwitchWebBrowserDisplayMgr ()

@property (readonly) TwitchBrowserViewController * browserController;

@end

@implementation TwitchWebBrowserDisplayMgr

@synthesize composeTweetDisplayMgr, hostViewController;

static TwitchWebBrowserDisplayMgr * gInstance = NULL;

+ (TwitchWebBrowserDisplayMgr *)instance
{
    @synchronized (self) {
        if (gInstance == NULL)
            gInstance = [[self alloc] init];
    }

    return gInstance;
}

- (void)visitWebpage:(NSString *)webpageUrl
{
    NSLog(@"Visiting webpage: %@", webpageUrl);
    [self.hostViewController presentModalViewController:self.browserController
        animated:YES];
    [self.browserController setUrl:webpageUrl];
}

- (TwitchBrowserViewController *)browserController
{
    if (!browserController) {
        browserController =
            [[TwitchBrowserViewController alloc]
            initWithNibName:@"TwitchBrowserView" bundle:nil];
        browserController.delegate = self;
    }

    return browserController;
}

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Composing tweet with text'%@'", text);
    [composeTweetDisplayMgr composeTweetWithText:text];
}

@end
