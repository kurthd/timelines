//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsTableViewCell.h"
#import "TrendsTableViewCellView.h"

@implementation TrendsTableViewCell

- (void)dealloc
{
    [trendsView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect frame =
            CGRectMake(0.0,
                       0.0,
                       self.contentView.bounds.size.width,
                       self.contentView.bounds.size.height);
        trendsView = [[TrendsTableViewCellView alloc] initWithFrame:frame];
        trendsView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;
        trendsView.contentMode = UIViewContentModeTopLeft;

        [self.contentView addSubview:trendsView];
    }

    return self;
}

#pragma mark Public implementation

- (void)setTitle:(NSString *)title
{
    [trendsView setTitle:title];
}

- (void)setExplanation:(NSString *)explanation
{
    [trendsView setExplanation:explanation];
}

+ (CGFloat)heightForTitle:(NSString *)title explanation:(NSString *)explanation
{
    return [TrendsTableViewCellView heightForTitle:title
                                       explanation:explanation];
}

@end
