//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FindPeopleBookmarkViewControllerDelegate

- (NSArray *)savedSearches;
- (BOOL)removeSavedSearchWithQuery:(NSString *)query;
- (void)setSavedSearchOrder:(NSArray *)savedSearches;

- (NSArray *)recentSearches;

- (void)clearRecentSearches;

- (void)userDidSelectSearchQuery:(NSString *)query;
- (void)userDidCancel;

@end

@interface FindPeopleBookmarkViewController : UIViewController
{
    id<FindPeopleBookmarkViewControllerDelegate> delegate;

    IBOutlet UINavigationBar * navigationBar;

    IBOutlet UITableView * tableView;
    IBOutlet UISegmentedControl * bookmarkCategorySelector;

    IBOutlet UIBarButtonItem * doneButton;
    IBOutlet UIBarButtonItem * clearRecentsButton;
    IBOutlet UIBarButtonItem * editSavedSearchesButton;
    IBOutlet UIBarButtonItem * doneEditingSavedSearchesButton;

    NSArray * contents;
}

@property (nonatomic, assign) id<FindPeopleBookmarkViewControllerDelegate>
    delegate;

#pragma mark Button actions

- (IBAction)done;
- (IBAction)clearRecentSearches;
- (IBAction)editSavedSearches;
- (IBAction)doneEditingSavedSearches;

@end
