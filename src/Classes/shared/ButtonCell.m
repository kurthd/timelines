//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ButtonCell.h"

@implementation ButtonCell

- (void)dealloc
{
    [buttonLabel release];
    [super dealloc];
}

- (void)setText:(NSString *)text
{
    buttonLabel.text = text;
}

- (void)setButtonTextColor:(UIColor *)color
{
    buttonLabel.textColor = color;
}

@end
