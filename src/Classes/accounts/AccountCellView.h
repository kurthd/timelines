//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountCellView : UIView
{
    NSString * username;

    UIImage * avatar;
	BOOL highlighted;
    BOOL landscape;
    BOOL selectedAccount;

    UIImage * checkMark;
    UIImage * highlightedCheckMark;
}

@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, assign) BOOL selectedAccount;

- (id)initWithFrame:(CGRect)frame;
- (void)setUsername:(NSString *)aUsername;

@end
