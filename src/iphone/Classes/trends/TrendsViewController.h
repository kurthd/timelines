//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrendsViewControllerDelegate.h"

@interface TrendsViewController : UITableViewController
{
    id<TrendsViewControllerDelegate> delegate;

    NSArray * trends;
}

@property (nonatomic, assign) id<TrendsViewControllerDelegate> delegate;

- (void)updateWithTrends:(NSArray *)trends;

@end
