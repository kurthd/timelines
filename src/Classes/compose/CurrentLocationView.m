//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CurrentLocationView.h"

@implementation CurrentLocationView

@synthesize delegate;

- (void)dealloc
{
    self.delegate = nil;

    [pushpinImageView release];
    [errorImageView release];
    [activityIndicator release];
    [descriptionLabel release];
    [infoButton release];
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
        [infoButton setHidden:YES];
    } else {
        [activityIndicator stopAnimating];
        [pushpinImageView setHidden:NO];
        [infoButton setHidden:NO];
    }
}

- (void)setErrorMessage:(NSString *)errorMessage
{
    [activityIndicator stopAnimating];
    [pushpinImageView setHidden:YES];
    [infoButton setHidden:YES];
    descriptionLabel.text = errorMessage;
    [errorImageView setHidden:NO];
}

- (IBAction)userDidTapInfoButton:(id)sender
{
    [self.delegate userDidTouchView:self];
}

/*
#pragma mark UIResponder overrides

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"Touches ended: %@ with event: %@", touches, event);

    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if ([self pointInside:point withEvent:event]) {
        NSLog(@"Point is inside.");
        [self.delegate userDidTouchView:self];
    } else
        NSLog(@"Point is outside.");
}
*/

@end
