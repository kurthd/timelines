//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessage.h"

@protocol DirectMessageConversationViewControllerDelegate

- (void)selectedTweet:(DirectMessage *)tweet avatarImage:(UIImage *)avatarImage;

@end
