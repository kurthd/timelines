//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface UserSummaryView : UIView
{
    User * user;

    UIImage * avatar;
	BOOL highlighted;
    BOOL landscape;
}

@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)aBackgroundColor;
- (void)setUser:(User *)aUser;

@end
