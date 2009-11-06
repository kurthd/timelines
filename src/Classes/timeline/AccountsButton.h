//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountsButton : UIControl
{
    NSString * username;
    UIImage * avatar;
    UIImage * dropDownArrow;
    UIImage * highlightedDropDownArrow;
    UIImage * avatarBackground;
    UIImage * highlightedAvatarMask;

    IBOutlet id target;
    SEL action;
}

- (void)setUsername:(NSString * )username avatar:(UIImage *)avatar;

@property (nonatomic, assign) SEL action;

@end
