//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServiceSelectorViewController.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface PhotoServiceSelectorViewController ()

@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, copy) NSArray * names;
@property (nonatomic, copy) NSArray * logos;

@end

@implementation PhotoServiceSelectorViewController

@synthesize delegate, cancelButton, names, logos, allowCancel;

- (void)dealloc
{
    self.delegate = nil;

    self.cancelButton = nil;

    self.names = nil;
    self.logos = nil;

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

    NSDictionary * services = [self.delegate photoServices];
    self.names =
        [[services allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray * theLogos = [NSMutableArray array];

    for (NSString * name in self.names) {
        UIImage * logo = [services objectForKey:name];
        [theLogos addObject:logo];
    }
    self.logos = theLogos;

    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.names.count;
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

    UIImage * logo = [self.logos objectAtIndex:indexPath.row];

    UIImageView * logoView = [[UIImageView alloc] initWithImage:logo];

    NSArray * subviews = cell.contentView.subviews;
    for (UIView * subview in subviews)
        [subview removeFromSuperview];  // remove the previous logo

    // Center the logo horizontally and vertically. Note that the content
    // view's rect is not set correctly (the height is wrong; the width
    // doesn't change), so we query for the value manually.
    CGRect imageFrame = logoView.frame;
    CGRect contentViewFrame = cell.contentView.frame;
    imageFrame.origin.x =
        (contentViewFrame.size.width - imageFrame.size.width) / 2.0;
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
    NSString * serviceName = [self.names objectAtIndex:indexPath.row];
    [self.delegate userSelectedServiceNamed:serviceName];
}

#pragma mark Button actions

- (IBAction)userDidCancel:(id)sender
{
    [self.delegate userDidCancel];
}

@end
