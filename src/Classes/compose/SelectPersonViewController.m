//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SelectPersonViewController.h"
#import "User.h"
#import "Avatar+UIAdditions.h"

@interface SelectPersonViewController ()

@property (nonatomic, copy) NSArray * people;
@property (nonatomic, copy) NSArray * filteredPeople;

- (void)initializeNavigationItem;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
            inTableView:(UITableView *)tv;

@end

@implementation SelectPersonViewController

@synthesize delegate, people, filteredPeople;

- (void)dealloc
{
    self.delegate = nil;

    self.people = nil;
    self.filteredPeople = nil;

    [super dealloc];
}

#pragma mark Initialization

- (id)initWithDelegate:(id<SelectPersonViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"SelectPersonView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark Public implementation

- (void)displayPeople:(NSArray *)somePeople
{
    self.people = somePeople;
    [self.tableView reloadData];
}

#pragma mark UIViewController implementation

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeNavigationItem];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return tv == self.tableView ? self.people.count : self.filteredPeople.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"SelectPersonTableViewCell";

    UITableViewCell * cell =
        [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:CellIdentifier]
            autorelease];

    User * user = [self objectAtIndexPath:indexPath inTableView:tv];

    cell.textLabel.text = user.username;
    cell.detailTextLabel.text = user.name;

    UIImage * avatar = [UIImage imageWithData:user.avatar.thumbnailImage];
    if (!avatar)
        avatar = [Avatar defaultAvatar];
    cell.imageView.image = avatar;

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [self objectAtIndexPath:indexPath inTableView:tv];
    [self.delegate userDidSelectPerson:user];
}

#pragma mark UISearchDisplayControllerDelegate implementation

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
    shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"SELF.username contains[cd] %@ OR SELF.name contains[cd] %@",
        searchString, searchString];
    self.filteredPeople = [self.people filteredArrayUsingPredicate:predicate];

    return YES;
}

#pragma mark Private implementation

- (void)userDidCancel:(id)sender
{
    [self.delegate userDidCancelPersonSelection];
}

- (void)initializeNavigationItem
{
    // Set the view title
    self.navigationItem.title =
        NSLocalizedString(@"selectpersonview.title", @"");

    // Set up the cancel button
    UIBarButtonItem * cancelButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(userDidCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
            inTableView:(UITableView *)tv
{
    NSArray * array = tv == self.tableView ? self.people : self.filteredPeople;
    return [array objectAtIndex:indexPath.row];
}

@end
