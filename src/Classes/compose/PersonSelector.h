//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectPersonViewController.h"

@protocol PersonSelectorDelegate;
@class PersonDirectory;
@class User;

@interface PersonSelector : NSObject <SelectPersonViewControllerDelegate>
{
    id<PersonSelectorDelegate> delegate;

    UIViewController * rootViewController;
    UINavigationController * navigationController;
    SelectPersonViewController * selectPersonViewController;

    NSManagedObjectContext * context;
    PersonDirectory * directory;
}

@property (nonatomic, assign) id<PersonSelectorDelegate> delegate;

- (id)initWithContext:(NSManagedObjectContext *)aContext;
- (void)promptToSelectUserModally:(UIViewController *)aController;

@end


@protocol PersonSelectorDelegate

- (void)userDidSelectPerson:(User *)user;
- (void)userDidCancelPersonSelection;

@end
