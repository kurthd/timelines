//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TwitterCredentials, Tweet;


@protocol TwitbitObjectCreator <NSObject>
- (id)createObjectFromJson:(NSDictionary *)json;
@end



@interface UserTwitbitObjectCreator : NSObject <TwitbitObjectCreator>
{
    NSManagedObjectContext * context;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext;

@end



@interface TweetTwitbitObjectCreator : NSObject <TwitbitObjectCreator>
{
    NSManagedObjectContext * context;
    id<TwitbitObjectCreator> userCreator;
    id<TwitbitObjectCreator> retweetCreator;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
                       userCreator:(id<TwitbitObjectCreator>)aUserCreator
                    retweetCreator:(id<TwitbitObjectCreator>)aRetweetCreator;


#pragma mark Protected interface

- (Tweet *)findTweetWithId:(NSNumber *)tweetId;
- (Tweet *)createInstance:(NSDictionary *)json;
- (void)populateTweet:(Tweet *)tweet fromJson:(NSDictionary *)json;

@end



@interface UserEntityTwitbitObjectCreator : TweetTwitbitObjectCreator
{
    TwitterCredentials * credentials;
    NSString * entityName;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctxt
                       userCreator:(id<TwitbitObjectCreator>)uc
                    retweetCreator:(id<TwitbitObjectCreator>)rc
                       credentials:(TwitterCredentials *)cdtls
                        entityName:(NSString *)aName;

@end



@interface DirectMessageTwitbitObjectCreator : NSObject <TwitbitObjectCreator>
{
    NSManagedObjectContext * context;
    id<TwitbitObjectCreator> userCreator;
    TwitterCredentials * credentials;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctxt
                       userCreator:(id<TwitbitObjectCreator>)uc
                       credentials:(TwitterCredentials *)cdtls;

@end

