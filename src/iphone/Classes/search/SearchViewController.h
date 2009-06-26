//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchViewControllerDelegate.h"

@interface SearchViewController : UITableViewController
{
    id<SearchViewControllerDelegate> delegate;

    NSArray * searchResults;
}

@property (nonatomic, assign) id<SearchViewControllerDelegate> delegate;

#pragma mark Updating the dispaly

- (void)updateWithSearchResults:(NSArray *)searchResults;

@end
