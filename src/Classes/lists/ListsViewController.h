//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ListsViewControllerDelegate

- (void)userDidSelectListWithId:(NSNumber *)identifier;

@end

@interface ListsViewController :
    UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSObject<ListsViewControllerDelegate> * delegate;

    NSDictionary * lists;
    NSDictionary * subscriptions;

    NSArray * sortedListCache;
    NSArray * sortedSubscriptionCache;
}

@property (nonatomic, assign) NSObject<ListsViewControllerDelegate> * delegate;

- (void)setLists:(NSDictionary *)lists
    subscriptions:(NSDictionary *)subscriptions
    pagesShown:(NSUInteger)pagesShown;

@end
