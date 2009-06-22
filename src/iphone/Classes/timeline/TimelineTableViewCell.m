//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"

@implementation TimelineTableViewCell

- (void)dealloc
{
    [avatar release];
    [super dealloc];
}

- (void)awakeFromNib
{
    UIImage * backgroundImage =
        [UIImage imageNamed:@"TableViewCellGradient.png"];
    self.backgroundView =
        [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
    self.backgroundView.contentMode =  UIViewContentModeBottom;

    avatar.radius = 4;
}

@end
