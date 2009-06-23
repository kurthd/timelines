//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "TimelineViewControllerDelegate.h"

@interface TimelineViewController : UITableViewController
{
    NSObject<TimelineViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIView * footerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * followingLabel;
    IBOutlet UILabel * currentPagesLabel;

    NSArray * tweets;
    NSMutableDictionary * avatarCache;

    NSArray * sortedTweetCache;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets page:(NSUInteger)page;

- (IBAction)loadMoreTweets:(id)sender;

- (void)addTweet:(TweetInfo *)tweet;

@end
