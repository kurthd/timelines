//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwoLineButton.h"

@interface TwoLineButton ()

@property (nonatomic, copy) NSString * lineOne;
@property (nonatomic, copy) NSString * lineTwo;

@end

@implementation TwoLineButton

@synthesize action;
@synthesize lineOne, lineTwo;

- (void)dealloc
{
    [lineOne release];
    [lineTwo release];
    [super dealloc];
}

- (void)setLineOne:(NSString * )lineOneText lineTwo:(NSString *)lineTwoText
{
    self.lineOne = lineOneText;
    self.lineTwo = lineTwoText;
}

#pragma mark UIView overrides

- (void)drawRect:(CGRect)rect
{}

@end
