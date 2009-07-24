//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessagesDisplayMgr.h"
#import "NewDirectMessagesState.h"

@interface DirectMessageAcctMgr : NSObject
{
    DirectMessagesDisplayMgr * displayMgr;
    NSMutableDictionary * newMessageStates;
}

- (id)initWithDirectMessagesDisplayMgr:(DirectMessagesDisplayMgr *)displayMgr;

- (void)processAccountChangeToUsername:(NSString *)toUsername
    fromUsername:(NSString *)fromUsername;
- (void)processAccountRemovedForUsername:(NSString *)username;

@end
