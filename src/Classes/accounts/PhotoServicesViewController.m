//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesViewController.h"

@implementation PhotoServicesViewController

@synthesize delegate, credentials;

- (void)dealloc
{
    self.delegate = nil;
    self.credentials = nil;

    [super dealloc];
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
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];
    }

    // Set up the cell...

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
