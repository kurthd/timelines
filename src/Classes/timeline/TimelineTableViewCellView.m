//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TimelineTableViewCellView.h"

@implementation TimelineTableViewCellView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
}

- (void)dealloc
{
    [super dealloc];
}

@end
