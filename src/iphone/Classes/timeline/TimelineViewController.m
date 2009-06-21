//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"

@implementation TimelineViewController

- (void)dealloc
{
    [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
            initWithFrame:CGRectZero reuseIdentifier:cellIdentifier]
            autorelease];

    return cell;
}


- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end

