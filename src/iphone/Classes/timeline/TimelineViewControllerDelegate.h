//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@protocol TimelineViewControllerDelegate

- (void)selectedTweet:(Tweet *)tweet;

@end
