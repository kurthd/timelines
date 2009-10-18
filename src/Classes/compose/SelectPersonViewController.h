//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsynchronousNetworkFetcher.h"

@class User;
@protocol SelectPersonViewControllerDelegate;

@interface SelectPersonViewController :
    UITableViewController
    <UISearchBarDelegate, AsynchronousNetworkFetcherDelegate>
{
    id<SelectPersonViewControllerDelegate> delegate;

    NSArray * people;
    NSArray * filteredPeople;
}

@property (nonatomic, assign) id<SelectPersonViewControllerDelegate> delegate;

- (id)initWithDelegate:(id<SelectPersonViewControllerDelegate>)aDelegate;
- (void)displayPeople:(NSArray *)somePeople;

@end

@protocol SelectPersonViewControllerDelegate

- (void)userDidSelectPerson:(User *)user;
- (void)userDidCancelPersonSelection;

@end
