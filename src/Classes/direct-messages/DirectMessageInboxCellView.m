//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxCellView.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"

@interface DirectMessageInboxCellView ()

+ (UIImage *)dotImage;

@end

@implementation DirectMessageInboxCellView

static UIImage * dotImage;

@synthesize highlighted, landscape;

- (void)dealloc
{
    [preview release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor =
		    [SettingsReader displayTheme] == kDisplayThemeDark ?
		    [UIColor defaultDarkThemeCellColor] :
		    [UIColor whiteColor];
	}

	return self;
}

- (void)setHighlighted:(BOOL)lit {
	if (highlighted != lit) {
		highlighted = lit;	
		[self setNeedsDisplay];
	}
}

- (void)setLandscape:(BOOL)l
{
    if (landscape != l) {
        landscape = l;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
#define LEFT_MARGIN 32
#define RIGHT_MARGIN 3

#define TOP_MARGIN 2

#define NAME_LABEL_WIDTH 167
#define NAME_LABEL_FONT_SIZE 16

#define DATE_LABEL_OFFSET 207
#define DATE_LABEL_WIDTH 84
#define DATE_LABEL_FONT_SIZE 14
#define MIN_DATE_LABEL_FONT_SIZE 12

#define PREVIEW_LABEL_TOP_MARGIN 23
#define PREVIEW_LABEL_WIDTH 259
#define PREVIEW_LABEL_WIDTH_LANDSCAPE 419
#define PREVIEW_LABEL_HEIGHT 34

#define DOT_IMAGE_TOP_MARGIN 23
#define DOT_IMAGE_LEFT_MARGIN 9

	UIColor * nameLabelTextColor = nil;
    UIFont * nameLabelFont = [UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE];

	UIColor * dateLabelTextColor = nil;
	UIFont * dateLabelFont = [UIFont systemFontOfSize:DATE_LABEL_FONT_SIZE];
    UIFont * smallDateLabelFont = [UIFont systemFontOfSize:12.5];
    UIFont * boldDateLabelFont =
        [UIFont boldSystemFontOfSize:DATE_LABEL_FONT_SIZE];

	UIColor * previewLabelTextColor = nil;
	UIFont * previewLabelFont = [UIFont systemFontOfSize:14];

	if (self.highlighted) {
		nameLabelTextColor = [UIColor whiteColor];
		dateLabelTextColor = [UIColor whiteColor];
		previewLabelTextColor = [UIColor whiteColor];
	} else {
		nameLabelTextColor =
		    [SettingsReader displayTheme] == kDisplayThemeDark ?
		    [UIColor whiteColor] :
		    [UIColor blackColor];
		dateLabelTextColor =
		    [SettingsReader displayTheme] == kDisplayThemeDark ?
		    [UIColor twitchBlueOnDarkBackgroundColor] :
		    [UIColor twitchBlueColor];
		previewLabelTextColor = 
		    [SettingsReader displayTheme] == kDisplayThemeDark ?
		    [UIColor twitchLightLightGrayColor] :
		    [UIColor grayColor];
		self.backgroundColor =
		    [SettingsReader displayTheme] == kDisplayThemeDark ?
		    [UIColor defaultDarkThemeCellColor] :
		    [UIColor whiteColor];
	}

	CGRect contentRect = self.bounds;
	
	CGFloat boundsX = contentRect.origin.x;
	CGPoint point;

	CGSize size;

    //
    // Draw name label
    //

	[nameLabelTextColor set];
	point =
	    CGPointMake(boundsX + LEFT_MARGIN, TOP_MARGIN);
	[preview.otherUserName drawAtPoint:point forWidth:NAME_LABEL_WIDTH
	    withFont:nameLabelFont minFontSize:NAME_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    //
    // Draw date label
    //

    [dateLabelTextColor set];
    if ([preview.mostRecentMessageDate isToday]) {
        CGFloat timestampWidth = 0.0;

        NSString * amPmString = preview.descriptionComponents.amPmString;
        timestampWidth = [amPmString sizeWithFont:smallDateLabelFont].width;
        point =
            CGPointMake(
            (contentRect.origin.x + contentRect.size.width) - RIGHT_MARGIN -
            timestampWidth,
            TOP_MARGIN + 2);
        [amPmString drawAtPoint:point withFont:smallDateLabelFont];

        NSString * timeString = preview.descriptionComponents.timeString;
        timestampWidth += [timeString sizeWithFont:boldDateLabelFont].width + 2;
        point =
            CGPointMake(
            (contentRect.origin.x + contentRect.size.width) - RIGHT_MARGIN -
            timestampWidth,
            TOP_MARGIN);
        [timeString drawAtPoint:point withFont:boldDateLabelFont];
    } else {
        NSString * timestamp = [preview dateDescription];
        size = [timestamp sizeWithFont:dateLabelFont];
    	point =
    	    CGPointMake(
            (contentRect.origin.x + contentRect.size.width) - RIGHT_MARGIN -
            size.width,
            TOP_MARGIN);
        [timestamp drawAtPoint:point forWidth:DATE_LABEL_WIDTH
    	    withFont:dateLabelFont minFontSize:MIN_DATE_LABEL_FONT_SIZE
    	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
    	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    }

    //
    // Draw preview text
    //

    NSString * previewText =
        [preview.mostRecentMessage stringByDecodingHtmlEntities];
    [previewLabelTextColor set];
    CGFloat previewLabelWidth = 
        !landscape ? PREVIEW_LABEL_WIDTH : PREVIEW_LABEL_WIDTH_LANDSCAPE;
    CGSize maxPreviewSize =
        CGSizeMake(previewLabelWidth, PREVIEW_LABEL_HEIGHT);
    size =
        [previewText sizeWithFont:previewLabelFont
        constrainedToSize:maxPreviewSize
        lineBreakMode:UILineBreakModeTailTruncation];
    point = CGPointMake(LEFT_MARGIN, PREVIEW_LABEL_TOP_MARGIN);

    CGRect drawingRect = CGRectMake(LEFT_MARGIN, PREVIEW_LABEL_TOP_MARGIN,
        size.width, size.height);

    [previewText drawInRect:drawingRect withFont:previewLabelFont
        lineBreakMode:UILineBreakModeTailTruncation];

    if (preview.numNewMessages > 0) {
        point =
            CGPointMake(boundsX + DOT_IMAGE_LEFT_MARGIN, DOT_IMAGE_TOP_MARGIN);
        [[[self class] dotImage] drawAtPoint:point];
    }
}

- (void)setConversationPreview:(ConversationPreview *)aPreview
{
    [aPreview retain];
    [preview release];
    preview = aPreview;

    [self setNeedsDisplay];
}

+ (UIImage *)dotImage
{
    if (!dotImage)
        dotImage = [[UIImage imageNamed:@"NewMessagesDot.png"] retain];

    return dotImage;
}

@end
