//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SendTweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "UserTweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface SendTweetResponseProcessor ()

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSNumber * referenceId;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation SendTweetResponseProcessor

@synthesize text, referenceId, credentials, context, delegate;

+ (id)processorWithTweet:(NSString *)someText
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithTweet:someText
                                     referenceId:aReferenceId
                                     credentials:someCredentials
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.text = nil;
    self.referenceId = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweet:(NSString *)someText
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.text = someText;
        self.referenceId = aReferenceId;
        self.credentials = someCredentials;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses lastObject];

    NSDictionary * userData = [status objectForKey:@"user"];
    NSNumber * userId = [userData objectForKey:@"id"];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:userData];

    NSDictionary * tweetData = status;

    NSNumber * tweetId = [tweetData objectForKey:@"id"];
    UserTweet * tweet = [UserTweet tweetWithId:tweetId context:context];
    if (!tweet)
        tweet = [UserTweet createInstance:context];

    [self populateTweet:tweet fromData:tweetData
        isSearchResult:NO context:context];
    tweet.user = user;
    tweet.credentials = self.credentials;

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    if (referenceId) {
        SEL sel = @selector(tweet:sentInReplyTo:);
        if ([delegate respondsToSelector:sel])
            [delegate tweet:tweet sentInReplyTo:referenceId];
    } else {
        SEL sel = @selector(tweetSentSuccessfully:);
        if ([delegate respondsToSelector:sel])
            [delegate tweetSentSuccessfully:tweet];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    if (referenceId) {
        SEL sel = @selector(failedToReplyToTweet:withText:error:);
        if ([delegate respondsToSelector:sel])
            [delegate
                failedToReplyToTweet:referenceId withText:text error:error];
    } else {
        SEL sel = @selector(failedToSendTweet:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToSendTweet:text error:error];
    }

    return YES;
}

@end
