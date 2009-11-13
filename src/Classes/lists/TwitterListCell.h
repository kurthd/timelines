//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterList.h"
#import "TwitterListCellView.h"

@interface TwitterListCell : UITableViewCell
{
    TwitterListCellView * cellView;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier;

- (void)setList:(TwitterList *)list;
- (void)setLandscape:(BOOL)landscape;
- (void)redisplay;

@end
