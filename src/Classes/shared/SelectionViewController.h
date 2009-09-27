//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectionViewController;

@protocol SelectionViewControllerDelegate

- (NSArray *)allChoices:(SelectionViewController *)controller;
- (NSInteger)initialSelectedIndex:(SelectionViewController *)controller;

- (void)selectionViewController:(SelectionViewController *)controller
       userDidSelectItemAtIndex:(NSInteger)index;

@end

@interface SelectionViewController : UITableViewController
{
    id<SelectionViewControllerDelegate> delegate;

    NSString * viewTitle;

    NSArray * choices;
    NSInteger selectedIndex;
}

@property (nonatomic, assign) id<SelectionViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString * viewTitle;
@property (nonatomic, assign, readonly) NSInteger selectedIndex;

@end