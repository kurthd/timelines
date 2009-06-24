//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserSummaryTableViewCell.h"

@implementation UserSummaryTableViewCell

- (void)dealloc
{
    [avatarView release];
    [nameLabel release];
    [usernameLabel release];
    [followingLabel release];
    [super dealloc];
}

- (void)setAvatar:(UIImage *)avatar
{
    avatarView.imageView.image = avatar;
}

- (void)setName:(NSString *)name
{
    nameLabel.text = name;
}

- (void)setUsername:(NSString *)username
{
    usernameLabel.text = username;
}

- (void)setFollowingText:(NSString *)followingText
{
    followingLabel.text = followingText;
}

@end
