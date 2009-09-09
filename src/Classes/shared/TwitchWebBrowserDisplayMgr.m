//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchWebBrowserDisplayMgr.h"

@implementation TwitchWebBrowserDisplayMgr

@synthesize delegate, composeTweetDisplayMgr, hostViewController;
@synthesize browserController;

static TwitchWebBrowserDisplayMgr * gInstance = NULL;

+ (TwitchWebBrowserDisplayMgr *)instance
{
    @synchronized (self) {
        if (gInstance == NULL)
            gInstance = [[self alloc] init];
    }

    return gInstance;
}

- (void)dealloc
{
    self.delegate = nil;
    [browserController release];
    [composeTweetDisplayMgr release];
    [hostViewController release];
    [super dealloc];
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

- (void)composeTweetWithLink:(NSString *)link
{
    NSLog(@"Composing tweet with link'%@'", link);
    [composeTweetDisplayMgr composeTweetWithLink:link];
}

- (void)readLater:(NSString *)url
{
    [self.delegate readLater:url];
}

@end
