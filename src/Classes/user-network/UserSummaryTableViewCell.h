//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoundedImage.h"

@interface UserSummaryTableViewCell : UITableViewCell
{
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * followingLabel;
}

- (void)setAvatar:(UIImage *)avatar;
- (void)setName:(NSString *)name;
- (void)setUsername:(NSString *)username;
- (void)setFollowingText:(NSString *)followingText;

@end
