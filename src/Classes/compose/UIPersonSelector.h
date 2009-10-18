//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectPersonViewController.h"

@protocol UIPersonSelectorDelegate;
@class PersonDirectory;
@class User;

@interface UIPersonSelector : NSObject <SelectPersonViewControllerDelegate>
{
    id<UIPersonSelectorDelegate> delegate;

    UIViewController * rootViewController;
    UINavigationController * navigationController;
    SelectPersonViewController * selectPersonViewController;

    NSManagedObjectContext * context;
    PersonDirectory * directory;
}

@property (nonatomic, assign) id<UIPersonSelectorDelegate> delegate;

- (id)initWithContext:(NSManagedObjectContext *)aContext;

- (void)promptToSelectUserModally:(UIViewController *)aController;

@end


@protocol UIPersonSelectorDelegate

- (void)userDidSelectPerson:(User *)user;
- (void)userDidCancelPersonSelection;

@end
