//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "TimelineViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "RoundedImage.h"

@interface TimelineViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<TimelineViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * followingLabel;
    IBOutlet UILabel * currentPagesLabel;
    IBOutlet UIButton * loadMoreButton;
    IBOutlet UILabel * noMorePagesLabel;
    IBOutlet UIView * inboxOutboxView;
    IBOutlet UISegmentedControl * inboxOutboxControl;

    NSArray * tweets;
    NSMutableArray * outgoingTweets;
    NSMutableArray * incomingTweets;
    NSMutableDictionary * avatarCache;
    NSMutableDictionary * alreadySent;
    NSArray * invertedCellUsernames;
    BOOL showWithoutAvatars;
    User * user;

    NSArray * sortedTweetCache;
    NSArray * outgoingSortedTweetCache;
    NSArray * incomingSortedTweetCache;

    NSString * segregatedSenderUsername;
    BOOL showInbox;

    BOOL delayedRefreshTriggered;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;
@property (nonatomic, retain) NSArray * outgoingSortedTweetCache;
@property (nonatomic, retain) NSArray * incomingSortedTweetCache;

@property (nonatomic, copy) NSArray * invertedCellUsernames;
@property (nonatomic, assign) BOOL showWithoutAvatars;

@property (nonatomic, copy) NSString * segregatedSenderUsername;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets page:(NSUInteger)page
    visibleTweetId:(NSString *)visibleTweetId;
- (void)setAllPagesLoaded:(BOOL)allLoaded;
- (void)setSegregateTweetsFromUser:(NSString *)username;

- (IBAction)loadMoreTweets:(id)sender;
- (IBAction)showUserInfo:(id)sender;
- (IBAction)setInboxOutbox:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

- (void)addTweet:(TweetInfo *)tweet;
- (NSString *)mostRecentTweetId;

@end
