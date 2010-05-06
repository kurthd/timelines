//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TimelineSelectionViewControllerDelegate

- (void)showTimeline;
- (void)showMentions;
- (void)showFavorites;
- (void)showRetweets;
- (void)userDidSelectListWithId:(NSNumber *)identifier;

@end

@interface TimelineSelectionViewController :
    UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
    id<TimelineSelectionViewControllerDelegate> delegate;
    
    NSDictionary * lists;
    NSDictionary * subscriptions;
    
    NSArray * sortedListCache;
    NSArray * sortedSubscriptionCache;
}

@property (nonatomic, assign)
    id<TimelineSelectionViewControllerDelegate> delegate;

- (void)setLists:(NSDictionary *)lists
    subscriptions:(NSDictionary *)subscriptions;

@end
