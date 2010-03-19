//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServiceSelectorViewController.h"
#import "TwitbitShared.h"

static const NSInteger NUM_SECTIONS = 1;

@interface PhotoServiceSelectorViewController ()

@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, copy) NSDictionary * services;

- (NSArray *)arrangedServiceNames:(NSDictionary *)services;

@end

@implementation PhotoServiceSelectorViewController

@synthesize delegate, cancelButton, allowCancel, services;

- (void)dealloc
{
    self.delegate = nil;

    self.cancelButton = nil;
    self.services = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"photoserviceselector.view.title", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.leftBarButtonItem =
        self.allowCancel ?
        self.cancelButton :
        nil;

    NSMutableDictionary * allServices =
        [[self.delegate freePhotoServices] mutableCopy];
    [allServices addEntriesFromDictionary:[self.delegate premiumPhotoServices]];
    self.services = allServices;
    [allServices release];

    [self.tableView reloadData];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.services.count;
}

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"PhotoServiceSelectorTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:CellIdentifier]
            autorelease];

    NSArray * serviceNames = [self arrangedServiceNames:self.services];
    NSString * serviceName = [serviceNames objectAtIndex:indexPath.row];

    UIImage * logo = [services objectForKey:serviceName];
    UIImageView * logoView = [[UIImageView alloc] initWithImage:logo];

    NSArray * subviews = cell.contentView.subviews;
    for (UIView * subview in subviews)
        [subview removeFromSuperview];  // remove the previous logo

    // Center the logo horizontally and vertically. Note that the content
    // view's rect is not set correctly (the height is wrong; the width
    // doesn't change), so we query for the value manually.
    CGRect imageFrame = logoView.frame;
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat cellContentWidth = landscape ? 458 : 298;
    imageFrame.origin.x = (cellContentWidth - imageFrame.size.width) / 2.0;
    imageFrame.origin.y =
        ([self tableView:tv heightForRowAtIndexPath:indexPath] -
        logo.size.height) / 2;
    logoView.frame = imageFrame;

    [cell.contentView addSubview:logoView];
    [logoView release];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * serviceNames = [self arrangedServiceNames:self.services];
    NSString * serviceName = [serviceNames objectAtIndex:indexPath.row];

    [self.delegate userSelectedServiceNamed:serviceName];
}

#pragma mark Button actions

- (IBAction)userDidCancel:(id)sender
{
    [self.delegate userDidCancel];
}

#pragma mark Private implementation

- (NSArray *)arrangedServiceNames:(NSDictionary *)svcs
{
    return [svcs.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

@end
