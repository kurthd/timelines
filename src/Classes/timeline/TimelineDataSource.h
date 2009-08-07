//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"

@protocol TimelineDataSource

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page;
- (TwitterCredentials *)credentials;
- (void)setCredentials:(TwitterCredentials *)credentials;

- (BOOL)readyForQuery;

@end
