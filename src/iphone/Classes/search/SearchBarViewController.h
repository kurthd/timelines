//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchBarViewControllerDelegate.h"

@interface SearchBarViewController : UITableViewController
{
    id<SearchBarViewControllerDelegate> delegate;

    NSArray * searchResults;
}

@property (nonatomic, assign) id<SearchBarViewControllerDelegate> delegate;

- (void)updateWithSearchResults:(NSArray *)someSearchResults;

@end
