//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ListsViewController :
    UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSDictionary * lists;
    NSDictionary * subscriptions;

    NSArray * sortedListCache;
    NSArray * sortedSubscriptionCache;
}

- (void)setLists:(NSDictionary *)lists
    subscriptions:(NSDictionary *)subscriptions
    pagesShown:(NSUInteger)pagesShown;

@end
