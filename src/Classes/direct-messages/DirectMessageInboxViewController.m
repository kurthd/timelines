//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxViewController.h"
#import "DirectMessageInboxCell.h"
#import "ConversationPreview.h"
#import "UIColor+TwitchColors.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "TimelineTableViewCellView.h"
#import "TwitbitShared.h"

@implementation DirectMessageInboxViewController

#define ROW_HEIGHT 62

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

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];
        self.view.backgroundColor =
            [UIColor defaultDarkThemeCellColor];
        footerView.backgroundColor =
            [UIColor defaultDarkThemeCellColor];
        numMessagesLabel.textColor = [UIColor twitchLightLightGrayColor];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
        cell =
            [[[DirectMessageInboxCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier]
            autorelease];
		cell.frame = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
    }

    ConversationPreview * preview =
        [conversationPreviews objectAtIndex:indexPath.row];
    [cell setConversationPreview:preview];
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    [cell setLandscape:landscape];

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
    return ROW_HEIGHT;
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
    UIColor * titleColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor twitchBlueOnDarkBackgroundColor] : [UIColor twitchBlueColor];
    [loadMoreButton setTitleColor:titleColor
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
