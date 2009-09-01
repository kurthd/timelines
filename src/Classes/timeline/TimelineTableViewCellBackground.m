//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCellBackground.h"

static UIImage * backgroundImage;
static UIImage * topGradientImage;
static UIImage * mentionBottomImage;
static UIImage * mentionTopImage;
static UIImage * darkenedBottomImage;
static UIImage * darkenedTopImage;

@implementation TimelineTableViewCellBackground

@synthesize highlightForMention, darkenForOld;

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
    darkenedBottomImage =
        [[UIImage imageNamed:@"DarkenedTableViewCellGradient.png"] retain];
    darkenedTopImage =
        [[UIImage imageNamed:@"DarkenedTableViewCellTopGradient.png"] retain];
}

- (void)drawRect:(CGRect)rect
{
    UIImage * bottomImage;
    UIImage * topImage;
    if (highlightForMention) {
        bottomImage = mentionBottomImage;
        topImage = mentionTopImage;
    } else if (darkenForOld) {
        bottomImage = darkenedBottomImage;
        topImage = darkenedTopImage;
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

- (void)setDarkenForOld:(BOOL)darken
{
    if (darkenForOld != darken) {
        darkenForOld = darken;
        [self setNeedsDisplay];
    }
}

@end
