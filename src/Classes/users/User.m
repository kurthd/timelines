// 
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "User.h"

#import "DirectMessage.h"
#import "Tweet.h"

@implementation User 

@dynamic followersCount;
@dynamic profileImageUrl;
@dynamic webpage;
@dynamic friendsCount;
@dynamic bio;
@dynamic identifier;
@dynamic location;
@dynamic created;
@dynamic username;
@dynamic name;
@dynamic tweets;
@dynamic statusesCount;
@dynamic receivedDirectMessages;
@dynamic sentDirectMessages;

- (NSString *)description
{
    return self.username;
}

@end