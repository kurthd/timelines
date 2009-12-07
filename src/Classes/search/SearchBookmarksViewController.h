//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrendType.h"

@protocol SearchBookmarksViewControllerDelegate

- (NSArray *)savedSearches;
- (BOOL)removeSavedSearchWithQuery:(NSString *)query;
- (void)setSavedSearchOrder:(NSArray *)savedSearches;

- (NSArray *)recentSearches;
- (void)clearRecentSearches;

- (void)userDidSelectSearchQuery:(NSString *)query;
- (void)userDidCancel;

@end

@interface SearchBookmarksViewController : UIViewController
{
    id<SearchBookmarksViewControllerDelegate> delegate;

    IBOutlet UINavigationBar * navigationBar;

    IBOutlet UITableView * tableView;
    IBOutlet UISegmentedControl * bookmarkCategorySelector;

    IBOutlet UIBarButtonItem * doneButton;
    IBOutlet UIBarButtonItem * clearRecentsButton;
    IBOutlet UIBarButtonItem * editSavedSearchesButton;
    IBOutlet UIBarButtonItem * doneEditingSavedSearchesButton;

    NSArray * contents;

    // Fucking NIB hack:
    NSInteger selectedIndex;
}

@property (nonatomic, assign) id<SearchBookmarksViewControllerDelegate>
    delegate;

#pragma mark Button actions

- (IBAction)done;
- (IBAction)clearRecentSearches;
- (IBAction)editSavedSearches;
- (IBAction)doneEditingSavedSearches;

- (NSInteger)selectedSegment;
- (void)setSelectedSegment:(NSInteger)segment;

@end
