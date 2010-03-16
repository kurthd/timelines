//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServiceSelectorViewController.h"
#import "TwitbitShared.h"

static const NSInteger NUM_SECTIONS = 2;
enum {
    kFreePhotoServicesSection,
    kPremiumPhotoServicesSection
};

@interface PhotoServiceSelectorViewController ()

@property (nonatomic, retain) UIBarButtonItem * cancelButton;

/*
@property (nonatomic, copy) NSArray * names;
@property (nonatomic, copy) NSArray * logos;
*/

@property (nonatomic, copy) NSDictionary * freePhotoServices;
@property (nonatomic, copy) NSDictionary * premiumPhotoServices;

- (NSInteger)effectiveSection:(NSInteger)section;
- (NSDictionary *)servicesInSection:(NSInteger)section;
- (NSArray *)arrangedServiceNames:(NSDictionary *)services;

@end

@implementation PhotoServiceSelectorViewController

@synthesize delegate, cancelButton, /*names, logos,*/ allowCancel;
@synthesize freePhotoServices, premiumPhotoServices;

- (void)dealloc
{
    self.delegate = nil;

    self.cancelButton = nil;

    /*
    self.names = nil;
    self.logos = nil;
    */

    self.freePhotoServices = nil;
    self.premiumPhotoServices = nil;

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
        self.allowCancel?
        self.cancelButton :
        nil;

    self.freePhotoServices = [self.delegate freePhotoServices];
    self.premiumPhotoServices = [self.delegate premiumPhotoServices];

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
    NSInteger count = 0;
    for (NSInteger i = 0; i < NUM_SECTIONS; ++i)
        if ([self servicesInSection:i].count > 0)
            ++count;

    return count;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    section = [self effectiveSection:section];

    switch (section) {
        case kFreePhotoServicesSection:
            return LS(@"photoserviceselector.section.free.title");
        case kPremiumPhotoServicesSection:
            return LS(@"photoserviceselector.section.premium.title");
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    section = [self effectiveSection:section];
    return [self servicesInSection:section].count;
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

    NSInteger section = [self effectiveSection:indexPath.section];
    NSDictionary * services = [self servicesInSection:section];
    NSArray * serviceNames = [self arrangedServiceNames:services];
    NSString * serviceName = [serviceNames objectAtIndex:indexPath.row];
    UIImage * logo = [services objectForKey:serviceName];

    //UIImage * logo = [self.logos objectAtIndex:indexPath.row];

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
    NSInteger section = [self effectiveSection:indexPath.section];
    NSDictionary * services = [self servicesInSection:section];
    NSArray * serviceNames = [self arrangedServiceNames:services];
    NSString * serviceName = [serviceNames objectAtIndex:indexPath.row];

    [self.delegate userSelectedServiceNamed:serviceName];
}

#pragma mark Button actions

- (IBAction)userDidCancel:(id)sender
{
    [self.delegate userDidCancel];
}

#pragma mark Private implementation

- (NSInteger)effectiveSection:(NSInteger)section
{
    NSInteger effectiveSection = section;

    if ([self servicesInSection:kFreePhotoServicesSection].count == 0)
        effectiveSection += 1;

    return effectiveSection;
}

- (NSDictionary *)servicesInSection:(NSInteger)section
{
    switch (section) {
        case kFreePhotoServicesSection:
            return self.freePhotoServices;
        case kPremiumPhotoServicesSection:
            return self.premiumPhotoServices;
        default:
            return nil;
    }
}

- (NSArray *)arrangedServiceNames:(NSDictionary *)services
{
    return [services.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

@end
