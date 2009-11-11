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
    [self visitWebpage:webpageUrl withHtml:nil animated:YES];
}

- (void)visitWebpage:(NSString *)webpageUrl withHtml:(NSString *)html
    animated:(BOOL)animated
{
    NSLog(@"Visiting webpage: %@", webpageUrl);
    [self.hostViewController presentModalViewController:self.browserController
        animated:animated];
    if (!html)
        [self.browserController setUrl:webpageUrl];
    else
        [self.browserController setUrl:webpageUrl html:html];
}

- (NSString *)currentUrl
{
    return [browserController viewingUrl];
}

- (NSString *)currentHtml
{
    return [browserController viewingHtml];
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
    [composeTweetDisplayMgr composeTweetWithText:link animated:YES];
}

- (void)readLater:(NSString *)url
{
    [self.delegate readLater:url];
}

@end
