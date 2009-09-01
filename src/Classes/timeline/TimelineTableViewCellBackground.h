//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimelineTableViewCellBackground : UIView
{
    BOOL highlightForMention;
    BOOL darkenForOld;
}

@property (nonatomic, assign) BOOL highlightForMention;
@property (nonatomic, assign) BOOL darkenForOld;

@end
