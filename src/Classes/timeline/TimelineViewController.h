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
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIImageView * avatarBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerBottomLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIView * plainHeaderView;
    IBOutlet UIView * plainHeaderViewLine;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * numUpdatesLabel;
    IBOutlet UILabel * currentPagesLabel;
    IBOutlet UIButton * loadMoreButton;
    IBOutlet UILabel * noMorePagesLabel;

    NSArray * tweets;
    NSMutableDictionary * alreadySent;
    NSArray * invertedCellUsernames;
    BOOL showWithoutAvatars;
    User * user;

    NSArray * sortedTweetCache;

    BOOL showInbox;
    BOOL delayedRefreshTriggered;

    NSString * mentionUsername;
    NSString * mentionRegex;

    NSString * visibleTweetId;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;

@property (nonatomic, copy) NSArray * invertedCellUsernames;
@property (nonatomic, assign) BOOL showWithoutAvatars;

@property (nonatomic, retain) NSString * mentionUsername;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets page:(NSUInteger)page
    visibleTweetId:(NSString *)visibleTweetId;
- (void)setAllPagesLoaded:(BOOL)allLoaded;
- (void)selectTweetId:(NSString *)tweetId;

- (IBAction)loadMoreTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

- (void)addTweet:(TweetInfo *)tweet;
- (void)deleteTweet:(NSString *)tweetId;
- (NSString *)mostRecentTweetId;

// HACK: Exposed to allow for "Save Search" button
- (void)setTimelineHeaderView:(UIView *)aView;

@end
