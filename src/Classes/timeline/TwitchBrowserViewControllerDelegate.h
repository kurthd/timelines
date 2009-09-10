//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TwitchBrowserViewControllerDelegate

- (void)composeTweetWithLink:(NSString *)link;
- (void)readLater:(NSString *)url;

@end
