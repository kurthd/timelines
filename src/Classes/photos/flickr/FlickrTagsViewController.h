//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlickrTagsViewControllerDelegate

- (void)userWantsToAddTag;
- (void)userSelectedTags:(NSSet *)tags;

- (void)refreshData;

@end

@interface FlickrTagsViewController : UITableViewController
{
    id<FlickrTagsViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * refreshButton;

    NSArray * tags;
    NSSet * selectedTags;
}

@property (nonatomic, assign) id<FlickrTagsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray * tags;
@property (nonatomic, copy) NSSet * selectedTags;
@property (nonatomic, retain, readonly) UIBarButtonItem * refreshButton;

- (id)initWithDelegate:(id<FlickrTagsViewControllerDelegate>)aDelegate;

- (void)addSelectedTag:(NSString *)tag;

- (IBAction)refresh:(id)sender;

@end
