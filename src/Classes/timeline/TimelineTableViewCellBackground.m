//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCellBackground.h"

static UIImage * backgroundImage;
static UIImage * topGradientImage;
static UIImage * mentionBottomImage;
static UIImage * mentionTopImage;

@implementation TimelineTableViewCellBackground

@synthesize highlightForMention;

+ (void)initialize
{
    NSAssert(!backgroundImage, @"backgroundImage should be nil.");
    backgroundImage =
        [[UIImage imageNamed:@"TableViewCellGradient.png"] retain];
    topGradientImage =
        [[UIImage imageNamed:@"TableViewCellTopGradient.png"] retain];
    mentionBottomImage =
        [[UIImage imageNamed:@"MentionBottomGradient.png"] retain];
    mentionTopImage =
        [[UIImage imageNamed:@"MentionTopGradient.png"] retain];
}

- (void)drawRect:(CGRect)rect
{
    UIImage * bottomImage;
    UIImage * topImage;
    if (highlightForMention) {
        bottomImage = mentionBottomImage;
        topImage = mentionTopImage;
    } else {
        bottomImage = backgroundImage;
        topImage = topGradientImage;
    }
    
    CGRect backgroundImageRect =
        CGRectMake(0, self.bounds.size.height - bottomImage.size.height,
        320.0, backgroundImage.size.height);
    [bottomImage drawInRect:backgroundImageRect];

    CGRect topGradientImageRect = CGRectMake(0, 0, 320.0, topImage.size.height);
    [topImage drawInRect:topGradientImageRect];
}

- (void)setHighlightForMention:(BOOL)hfm
{
    if (highlightForMention != hfm) {
        highlightForMention = hfm;
        [self setNeedsDisplay];
    }
}

@end
