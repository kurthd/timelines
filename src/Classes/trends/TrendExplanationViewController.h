//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrendExplanationViewController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView * webView;
    NSString * explanation;
}

- (id)initWithHtmlExplanation:(NSString *)html;

@end
