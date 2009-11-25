//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CurrentLocationView.h"

@implementation CurrentLocationView

- (void)dealloc
{
    [activityIndicator release];
    [textField release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    return (self = [super initWithFrame:frame]);
}

#pragma mark Public implementation

- (void)setText:(NSString *)text
{
    textField.text = text;
}

- (void)displayActivity:(BOOL)displayActivity
{
    if (displayActivity)
        [activityIndicator startAnimating];
    else
        [activityIndicator stopAnimating];
}

@end
