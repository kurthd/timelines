//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SelectPersonViewController.h"
#import "TwitbitShared.h"
#import "User.h"
#import "User+UIAdditions.h"
#import "Avatar+UIAdditions.h"
#import "SettingsReader.h"

@interface SelectPersonViewController ()

@property (nonatomic, copy) NSArray * people;
@property (nonatomic, copy) NSArray * filteredPeople;

- (void)initializeNavigationItem;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
            inTableView:(UITableView *)tv;

+ (UIImage *)avatarByResizingIfNecessary:(UIImage *)avatar;
+ (CGSize)desiredAvatarSize;

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

    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    [self initializeNavigationItem];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
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
    if (!cell) {
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:CellIdentifier]
            autorelease];
    }

    User * user = [self objectAtIndexPath:indexPath inTableView:tv];

    cell.textLabel.text = user.username;
    cell.detailTextLabel.text = user.name;

    UIImage * avatar = [UIImage imageWithData:user.avatar.thumbnailImage];
    if (!avatar) {
        avatar = [Avatar defaultAvatar];
        NSURL * avatarUrl = [NSURL URLWithString:user.avatar.thumbnailImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
    }
    cell.imageView.image = [[self class] avatarByResizingIfNecessary:avatar];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [self objectAtIndexPath:indexPath inTableView:tv];
    [self.delegate userDidSelectPerson:user];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self class] desiredAvatarSize].height;
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

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatarImage = [UIImage imageWithData:data];
    NSString * urlAsString = [url absoluteString];
    [User setAvatar:avatarImage forUrl:urlAsString];

    // resize if necessary before displaying
    avatarImage = [[self class] avatarByResizingIfNecessary:avatarImage];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"SELF.avatar.thumbnailImageUrl == %@",
        urlAsString];
    NSArray * candidates = [self.people filteredArrayUsingPredicate:predicate];
    
    for (User * user in candidates) {  // there should only be one
        UITableView * visibleTableView =
            self.searchDisplayController.active ?
            self.searchDisplayController.searchResultsTableView :
            self.tableView;

        for (UITableViewCell * cell in visibleTableView.visibleCells)
            if ([user.username isEqualToString:cell.textLabel.text])
                cell.imageView.image = avatarImage;
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

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

+ (UIImage *)avatarByResizingIfNecessary:(UIImage *)avatar
{
    CGSize desiredSize = [[self class] desiredAvatarSize];
    return avatar.size.height > desiredSize.height ?
        [avatar imageByScalingProportionallyToSize:desiredSize] : avatar;
}

+ (CGSize)desiredAvatarSize
{
    return CGSizeMake(48, 48);
}

@end
