//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UIPersonSelector.h"
#import "PersonDirectory.h"

@interface UIPersonSelector ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) SelectPersonViewController *
    selectPersonViewController;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, retain) PersonDirectory * directory;

@end


@implementation UIPersonSelector

@synthesize delegate;
@synthesize rootViewController, navigationController;
@synthesize selectPersonViewController;
@synthesize context, directory;

- (void)dealloc
{
    self.delegate = nil;

    self.rootViewController = nil;
    self.navigationController = nil;
    self.selectPersonViewController = nil;

    self.context = nil;
    self.directory = nil;

    [super dealloc];
}

#pragma mark Initialization

- (id)initWithContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.context = aContext;
        directory = [[PersonDirectory alloc] init];
    }

    return self;
}

#pragma mark Public implementation

- (void)promptToSelectUserModally:(UIViewController *)aController
{
    self.rootViewController = aController;

    // Note that creating a new navigation controller instance every time
    // this function is called will break the behavior of the search bar in
    // the select person view. With the original instance of the nav
    // controller, when focus is given to the search bar, the search bar
    // will move to take the position occupied by the view's navigation
    // item. If we create a new instance every time, this behavior will
    // not work for all instances after the first one.
    if (!self.navigationController) {
        UINavigationController * nc =
            [[UINavigationController alloc]
            initWithRootViewController:self.selectPersonViewController];
        self.navigationController = nc;
        [nc release];
    }

    // reload the list of users every time we start the selection process
    [self.directory loadAllFromPersistence:self.context ofType:@"User"];
    NSArray * people =
        [[self.directory allPeople]
        sortedArrayUsingSelector:@selector(caseInsensitiveUsernameCompare:)];
    [self.selectPersonViewController displayPeople:people];

    [self.rootViewController
        presentModalViewController:self.navigationController animated:YES];
}

#pragma mark SelectPersonViewControllerDelegate implementation

- (void)userDidSelectPerson:(User *)user
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    [self.delegate userDidSelectPerson:user];
}

- (void)userDidCancelPersonSelection
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    [self.delegate userDidCancelPersonSelection];
}

#pragma mark Accessors

- (SelectPersonViewController *)selectPersonViewController
{
    if (!selectPersonViewController)
        selectPersonViewController =
            [[SelectPersonViewController alloc] initWithDelegate:self];

    return selectPersonViewController;
}

@end
