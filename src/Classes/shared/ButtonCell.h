//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ButtonCell : UITableViewCell
{
    IBOutlet UILabel * buttonLabel;
}

- (void)setText:(NSString *)text;
- (void)setButtonTextColor:(UIColor *)color;

@end
