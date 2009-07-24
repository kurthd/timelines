//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxViewController.h"
#import "DirectMessageInboxCell.h"
#import "ConversationPreview.h"
#import "UIColor+TwitchColors.h"

@implementation DirectMessageInboxViewController

@synthesize delegate;

- (void)dealloc
{
    [loadMoreButton release];
    [footerView release];
    [numMessagesLabel release];
    [conversationPreviews release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

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
    [delegate selectedConversationPreview:preview];
    preview.numNewMessages = 0;
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 62;
}

#pragma mark DirectMessageInboxViewController implementation

- (IBAction)loadMoreDirectMessages:(id)sender
{
    NSLog(@"'Load more direct messages' selected");
    [delegate loadAnotherPageOfMessages];
    [loadMoreButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = NO;
}

- (void)setConversationPreviews:(NSArray *)someConversationPreviews
{
    NSArray * tempConversationPreviews = [someConversationPreviews copy];
    [conversationPreviews release];
    conversationPreviews = tempConversationPreviews;

    [self.tableView reloadData];

    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
}

- (void)setNumReceivedMessages:(NSUInteger)receivedMessages
    sentMessages:(NSUInteger)sentMessages
{
    NSString * numMessagesFormatString =
        NSLocalizedString(@"directmessageinbox.nummessages", @"");
    numMessagesLabel.text =
        [NSString stringWithFormat:numMessagesFormatString,
        receivedMessages, sentMessages];
}

@end
