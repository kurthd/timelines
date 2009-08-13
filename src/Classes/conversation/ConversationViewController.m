//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ConversationViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "TweetInfo.h"
#import "TimelineTableViewCell.h"

@interface ConversationViewController ()

@property (nonatomic, retain) NSMutableArray * conversation;

@end

@implementation ConversationViewController

@synthesize delegate, conversation, batchSize;

- (void)dealloc
{
    self.delegate = nil;

    self.conversation = nil;
    self.batchSize = nil;

    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
        conversation = [[NSMutableArray alloc] init];

    return self;
}

#pragma mark Public Interface

- (void)loadConversationStartingWithTweets:(NSArray *)tweets
{
    [conversation removeAllObjects];
    [conversation addObjectsFromArray:tweets];

    TweetInfo * oldestTweet = [conversation lastObject];
    NSString * tweetId = oldestTweet.inReplyToTwitterTweetId;
    if (tweetId) { // there's still more to load
        [delegate fetchTweetWithId:tweetId];
        waitingFor = [batchSize integerValue];
    }

    [self.tableView reloadData];

    // TODO: Start any animations/loading indicators
}

- (void)addTweetsToConversation:(NSArray *)tweets
{
    [conversation addObjectsFromArray:tweets];

    NSMutableArray * indexPaths = [NSMutableArray array];
    NSInteger rowOffset = conversation.count - tweets.count;

    for (NSInteger i = 0; i < tweets.count; ++i) {
        NSIndexPath * indexPath =
            [NSIndexPath indexPathForRow:rowOffset + i inSection:0];
        [indexPaths addObject:indexPath];
    }

    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationTop];

    waitingFor -= tweets.count;
    NSString * nextId = [[conversation lastObject] inReplyToTwitterTweetId];

    if (waitingFor > 0 && nextId)
        [delegate fetchTweetWithId:nextId];
    else
        waitingFor = 0;

    // TODO: stop any animations
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"conversation.load.failed.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"conversationview.title", @"");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];  // Releases the view if it doesn't have a
                                      // superview

    // Release anything that's not essential, such as cached data
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
    return conversation.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"ConversationTableViewCell";

    TimelineTableViewCell * cell = (TimelineTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[TimelineTableViewCell alloc]
            initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier]
            autorelease];

    TweetInfo * tweet = [conversation objectAtIndex:indexPath.row];

    [cell setName:[tweet displayName]];
    [cell setDate:tweet.timestamp];
    [cell setTweetText:tweet.text];
    [cell setDisplayType:kTimelineTableViewCellTypeNormal];

    return cell;
}

#pragma mark UITabeViewDelegate implementation

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [conversation objectAtIndex:indexPath.row];
    TimelineTableViewCellType type = kTimelineTableViewCellTypeNormal;

    return [TimelineTableViewCell heightForContent:tweet.text displayType:type];
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * info = [conversation objectAtIndex:indexPath.row];
    [self.delegate displayTweetWithId:info.identifier];
}

@end
