//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlickrTagsViewControllerDelegate

@end

@interface FlickrTagsViewController : UITableViewController
{
    id<FlickrTagsViewControllerDelegate> delegate;

    NSArray * tags;
    NSSet * selectedTags;
}

@property (nonatomic, assign) id<FlickrTagsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray * tags;
@property (nonatomic, copy) NSSet * selectedTags;

- (id)initWithDelegate:(id<FlickrTagsViewControllerDelegate>)aDelegate;

@end
