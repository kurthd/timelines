//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountCellView.h"

@interface AccountTableViewCell : UITableViewCell
{
    AccountCellView * accountCellView;
}

@property (nonatomic, retain) AccountCellView * accountCellView;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier;

- (void)setUsername:(NSString *)username;
- (void)setAvatarImage:(UIImage *)avatarImage;
- (void)setLandscape:(BOOL)landscape;
- (void)setSelectedAccount:(BOOL)selectedAccount;

- (void)redisplay;

@end
