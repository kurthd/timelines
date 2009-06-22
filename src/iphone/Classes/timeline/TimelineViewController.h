//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface TimelineViewController : UITableViewController
{
    IBOutlet UIView * headerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * followingLabel;
    
    NSArray * tweets;
    NSMutableDictionary * avatarCache;
}

- (void)setUser:(User *)user;
- (void)setTweets:(NSArray *)tweets;

@end
