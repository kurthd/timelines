//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrendExplanationViewController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView * webView;
    NSString * explanation;

    id linkTapTarget;
    SEL linkTapAction;
}

@property (nonatomic, assign) id linkTapTarget;
@property (nonatomic, assign) SEL linkTapAction;

- (id)initWithHtmlExplanation:(NSString *)html;

@end
