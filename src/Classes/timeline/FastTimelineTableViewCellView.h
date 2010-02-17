//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastTimelineTableViewCellDisplayType.h"
#import "DateDescription.h"

@interface FastTimelineTableViewCellView : UIView
{
    BOOL highlighted;

    BOOL landscape;
    FastTimelineTableViewCellDisplayType displayType;

    NSString * text;
    NSString * author;
    DateDescription * timestamp;
    NSString * retweetAuthorName;
    UIImage * avatar;
    BOOL favorite;
    BOOL geocoded;
    BOOL attachment;

    BOOL displayAsMention;
    BOOL displayAsOld;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, assign) FastTimelineTableViewCellDisplayType displayType;
@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * retweetAuthorName;
@property (nonatomic, retain) DateDescription * timestamp;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) BOOL geocoded;

@property (nonatomic, assign) BOOL displayAsMention;
@property (nonatomic, assign) BOOL displayAsOld;

+ (CGFloat)heightForContent:(NSString *)tweetText
                    retweet:(BOOL)retweet
                displayType:(FastTimelineTableViewCellDisplayType)displayType
                  landscape:(BOOL)landscape;

@end
