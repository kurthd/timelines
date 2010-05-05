//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NoDataViewController.h"
#import "SettingsReader.h"

@implementation NoDataViewController

- (void)dealloc {
    [label release];
    [activityIndicator release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor blackColor];
    }
}

- (void)setLabelText:(NSString *)text
{
    label.text = text;
}

- (void)startAnimatingActivityIndicator
{
    [activityIndicator startAnimating];
}

- (void)stopAnimatingActivityIndicator
{
    [activityIndicator stopAnimating];
}

@end
