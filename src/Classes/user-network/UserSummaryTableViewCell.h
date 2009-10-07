//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "UserSummaryView.h"

@interface UserSummaryTableViewCell : UITableViewCell
{
    NSString * avatarImageUrl;
    UserSummaryView * userSummaryView;
}

@property (nonatomic, copy) NSString * avatarImageUrl;
@property (nonatomic, retain) UserSummaryView * userSummaryView;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)backgroundColor;

- (void)setUser:(User *)user;
- (void)setAvatarImage:(UIImage *)avatarImage;
- (void)setLandscape:(BOOL)landscape;

- (void)redisplay;

@end
