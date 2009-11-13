//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterList.h"

@interface TwitterListCellView : UIView
{
    TwitterList * list;
	BOOL highlighted;
    BOOL landscape;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;

- (void)setList:(TwitterList *)list;

@end
