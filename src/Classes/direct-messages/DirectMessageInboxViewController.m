//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxViewController.h"
#import "DirectMessageInboxCell.h"
#import "ConversationPreview.h"

@implementation DirectMessageInboxViewController

@synthesize delegate;

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return [conversationPreviews count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"DirectMessageInboxCell";

    DirectMessageInboxCell * cell =
        (DirectMessageInboxCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"DirectMessageInboxCell"
            owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    ConversationPreview * preview =
        [conversationPreviews objectAtIndex:indexPath.row];
    [cell setConversationPreview:preview];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConversationPreview * preview =
        [conversationPreviews objectAtIndex:indexPath.row];
    [delegate selectedConversationForUserId:preview.otherUserId];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66;
}

#pragma mark DirectMessageInboxViewController implementation

- (void)setConversationPreviews:(NSArray *)someConversationPreviews
{
    NSArray * tempConversationPreviews = [someConversationPreviews copy];
    [conversationPreviews release];
    conversationPreviews = tempConversationPreviews;

    [self.tableView reloadData];
}

@end
