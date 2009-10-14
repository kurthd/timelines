//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoLabelCell.h"

@implementation UserInfoLabelCell

- (void)dealloc
{
    [keyLabel release];
    [valueLabel release];
    [super dealloc];
}

- (void)setKeyText:(NSString *)text
{
    keyLabel.text = text;
}

- (void)setValueText:(NSString *)text
{
    valueLabel.text = text;
}

- (void)setKeyColor:(UIColor *)color
{
    keyLabel.textColor = color;
}

- (void)setValueColor:(UIColor *)color
{
    valueLabel.textColor = color;
}

@end
