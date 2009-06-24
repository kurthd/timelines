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

    NSArray * tweets;
    NSMutableDictionary * avatarCache;
    NSArray * invertedCellUsernames;
    BOOL showWithoutAvatars;
    User * user;

    NSArray * sortedTweetCache;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;
@property (nonatomic, copy) NSArray * invertedCellUsernames;
@property (nonatomic, assign) BOOL showWithoutAvatars;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets page:(NSUInteger)page;

- (IBAction)loadMoreTweets:(id)sender;
- (IBAction)showUserInfo:(id)sender;

- (void)addTweet:(TweetInfo *)tweet;

@end
