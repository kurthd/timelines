//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendExplanationViewController.h"
#import "TwitbitShared.h"

@interface TrendExplanationViewController ()
@property (nonatomic, copy) NSString * explanation;
@end

@implementation TrendExplanationViewController

@synthesize explanation;

- (void)dealloc
{
    self.explanation = nil;
    [super dealloc];
}

- (id)initWithHtmlExplanation:(NSString *)html
{
    if (self = [super initWithNibName:@"TrendExplanationView" bundle:nil])
        self.explanation = html;

    return self;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    [webView loadHTMLStringRelativeToMainBundle:self.explanation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    return YES;
}

@end

