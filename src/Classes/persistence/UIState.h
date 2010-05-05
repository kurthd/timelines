//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIState : NSObject
{
    NSInteger numNewMentions;

    BOOL composingTweet;

    NSString * viewingUrl;
    NSString * viewingHtml;

    NSNumber * currentlyViewedTweetId;
    NSNumber * currentlyViewedMentionId;

    NSUInteger timelineContentOffset;
    
    NSUInteger currentlyViewedTimeline;
}

@property (nonatomic, assign) NSInteger numNewMentions;

@property (nonatomic, assign) BOOL composingTweet;

@property (nonatomic, copy) NSString * viewingUrl;
@property (nonatomic, copy) NSString * viewingHtml;

@property (nonatomic, copy) NSNumber * currentlyViewedTweetId;
@property (nonatomic, copy) NSNumber * currentlyViewedMentionId;

@property (nonatomic, assign) NSUInteger timelineContentOffset;

@property (nonatomic, assign) NSUInteger currentlyViewedTimeline;

@end
