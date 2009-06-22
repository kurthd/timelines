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
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * followingLabel;
    
    NSArray * tweets;
    NSMutableDictionary * avatarCache;
}

@property (nonatomic, assign)
    NSObject<TimelineViewControllerDelegate> * delegate;

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets;

@end
