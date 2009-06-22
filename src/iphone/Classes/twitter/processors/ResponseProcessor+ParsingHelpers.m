//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor+ParsingHelpers.h"
#import "NSDate+TwitterStringHelpers.h"

@implementation ResponseProcessor (ParsingHelpers)

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
    user.username = [data objectForKey:@"screen_name"];
    user.name = [data objectForKey:@"name"];
    user.bio = [data objectForKey:@"description"];
    user.location = [data objectForKey:@"location"];

    // use key-value coding to convert strings to nsnumbers
    [user setValue:[data objectForKey:@"friends_count"]
            forKey:@"friendsCount"];
    [user setValue:[data objectForKey:@"followers_count"]
            forKey:@"followersCount"];

    NSDate * createdAt =
        [NSDate dateWithTwitterUserString:
        [data objectForKey:@"created_at"]];
    user.created = createdAt;

    user.webpage = [data objectForKey:@"url"];
    user.identifier = [[data objectForKey:@"id"] description];
    user.profileImageUrl = [data objectForKey:@"profile_image_url"];
}

@end
