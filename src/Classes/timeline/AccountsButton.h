//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoundedImage.h"

@interface AccountsButton : UIControl
{
    NSString * username;
    RoundedImage * avatar;
    UIImage * dropDownArrow;
    UIImage * highlightedDropDownArrow;
    UIImage * avatarBackground;
    UIImageView * highlightedAvatarMask;

    IBOutlet id target;
    SEL action;

    BOOL newUser;
}

- (void)setUsername:(NSString * )username avatar:(UIImage *)avatar;

@property (nonatomic, assign) SEL action;

@end
