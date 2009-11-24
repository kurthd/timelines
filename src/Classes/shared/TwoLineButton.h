//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwoLineButton : UIControl
{
    NSString * lineOne;
    NSString * lineTwo;

    IBOutlet id target;
    SEL action;
}

- (void)setLineOne:(NSString * )lineOne lineTwo:(NSString *)lineTwo;

@property (nonatomic, assign) SEL action;

@end
