//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CurrentLocationView.h"

@implementation CurrentLocationView

- (void)dealloc
{
    [pushpinImageView release];
    [errorImageView release];
    [activityIndicator release];
    [descriptionLabel release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    return (self = [super initWithFrame:frame]);
}

#pragma mark Public implementation

- (void)setText:(NSString *)text
{
    descriptionLabel.text = text;
    [errorImageView setHidden:YES];
}

- (void)displayActivity:(BOOL)displayActivity
{
    [errorImageView setHidden:YES];
    if (displayActivity) {
        [activityIndicator startAnimating];
        [pushpinImageView setHidden:YES];
    } else {
        [activityIndicator stopAnimating];
        [pushpinImageView setHidden:NO];
    }
}

- (void)setErrorMessage:(NSString *)errorMessage
{
    [activityIndicator stopAnimating];
    [pushpinImageView setHidden:YES];
    descriptionLabel.text = errorMessage;
    [errorImageView setHidden:NO];
}

@end
