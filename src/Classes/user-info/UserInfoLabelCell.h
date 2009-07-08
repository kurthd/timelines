//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfoLabelCell : UITableViewCell
{
    IBOutlet UILabel * keyLabel;
    IBOutlet UILabel * valueLabel;
}

- (void)setKeyText:(NSString *)text;
- (void)setValueText:(NSString *)text;

@end
