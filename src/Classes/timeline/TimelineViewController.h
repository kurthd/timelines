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
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIView * plainHeaderView;
    IBOutlet UIView * plainHeaderViewLine;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * numUpdatesLabel;
    IBOutlet UILabel * currentPagesLabel;
    IBOutlet UIButton * loadMoreButton;
    IBOutlet UIActivityIndicatorView * loadingMoreIndicator;
    IBOutlet UILabel * noMorePagesLabel;

    NSArray * tweets;
    NSMutableDictionary * alreadySent;
    NSArray * invertedCellUsernames;
    BOOL showWithoutAvatars;
    User * user;

    NSArray * sortedTweetCache;

    BOOL showInbox;
    BOOL delayedRefreshTriggered;
    BOOL flashingScrollIndicators;

    NSString * mentionUsername;
    NSString * mentionString;

    NSNumber * visibleTweetId;

    BOOL lastShownLandscapeValue;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;

@property (nonatomic, copy) NSArray * invertedCellUsernames;
@property (nonatomic, assign) BOOL showWithoutAvatars;

@property (nonatomic, retain) NSString * mentionUsername;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets page:(NSUInteger)page
    visibleTweetId:(NSNumber *)visibleTweetId;
- (void)setAllPagesLoaded:(BOOL)allLoaded;
- (void)selectTweetId:(NSString *)tweetId;

- (IBAction)loadMoreTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

- (void)addTweet:(Tweet *)tweet;
- (void)deleteTweet:(NSString *)tweetId;
- (NSNumber *)mostRecentTweetId;

// HACK: Exposed to allow for "Save Search" button
- (void)setTimelineHeaderView:(UIView *)aView;

@end
