//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "ManagedObjectContextPruner.h"
#import "TwitbitShared.h"

@interface ManagedObjectContextPruner ()
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) NSInteger numTweetsToKeep;
@property (nonatomic, assign) NSInteger numMentionsToKeep;
@property (nonatomic, assign) NSInteger numDirectMessagesToKeep;
@end

@implementation ManagedObjectContextPruner

@synthesize context;
@synthesize numTweetsToKeep, numMentionsToKeep, numDirectMessagesToKeep;

- (void)dealloc
{
    self.context = nil;
    [super dealloc];
}

#pragma mark Initialization

- (id)initWithContext:(NSManagedObjectContext *)aContext
      numTweetsToKeep:(NSInteger)numTweets
    numMentionsToKeep:(NSInteger)numMentions
         numDmsToKeep:(NSInteger)numDms
{
    if (self = [super init]) {
        self.context = aContext;
        self.numTweetsToKeep = numTweets;
        self.numMentionsToKeep = numMentions;
        self.numDirectMessagesToKeep = numDms;
    }

    return self;
}

#pragma mark Public implementation

- (void)pruneContext
{
    //
    // Preserve:
    //   - UserTweet instances (the timeline)
    //   - Mentions
    //   - DirectMessages
    //   - UserList instances (the user's lists)
    //   - The user objects on which all of these objects depend

    NSArray * credentials = [TwitterCredentials findAll:context];

    NSArray * allTweets = [Tweet findAll:context];
    NSMutableSet * sparedUsers = [NSMutableSet set];

    // all users bound to credentials will be spared
    for (TwitterCredentials * c in credentials)
        if (c.user)
            [sparedUsers addObject:c.user];

    // all users that own lists will be spared
    NSArray * allLists = [UserTwitterList findAll:context];
    for (UserTwitterList * list in allLists)
        [sparedUsers addObject:list.user];

    NSMutableDictionary * living =
        [NSMutableDictionary dictionaryWithCapacity:credentials.count];
    NSMutableSet * hitList =
        [NSMutableSet setWithCapacity:allTweets.count];

    // delete all 'un-owned' tweets -- everything that's not in the user's
    // timeline, a mention, or a dm
    for (Tweet * tweet in allTweets) {
        BOOL isOwned =
            [tweet isKindOfClass:[UserTweet class]] ||
            [tweet isKindOfClass:[Mention class]];
        if (!isOwned)
            [hitList addObject:tweet];
    }

    // won't include deleted tweets
    allTweets =
        [[[Tweet findAll:context] sortedArrayUsingSelector:@selector(compare:)]
        arrayByReversingContents];

    NSMutableSet * sparedRetweets =
        [NSMutableSet setWithCapacity:allTweets.count];
    for (NSInteger i = 0, count = allTweets.count; i < count; ++i) {
        Tweet * t = [allTweets objectAtIndex:i];
        NSString * key = nil;
        TwitterCredentials * c = nil;

        if ([t isKindOfClass:[UserTweet class]]) {
            c = [((UserTweet *) t) credentials];
            key = @"user-tweet";
        } else if ([t isKindOfClass:[Mention class]]) {
            c = [((Mention *) t) credentials];
            key = @"mention";
        } else if ([t.retweets count] > 0) {
            c = nil;
            key = nil;
        }

        if (c) {
            NSMutableDictionary * perCredentials =
                [living objectForKey:c.username];
            if (!perCredentials) {
                perCredentials = [NSMutableDictionary dictionary];
                [living setObject:perCredentials forKey:c.username];
            }

            NSMutableArray * perTweetType = [perCredentials objectForKey:key];
            if (!perTweetType) {
                perTweetType = [NSMutableArray array];
                [perCredentials setObject:perTweetType forKey:key];
            }

            // finally, insert the tweet if it should be saved
            // HACK: only using numTweetsToKeep; should be using both
            // numTweetstoKeep and numMentionsToKeep; refactory this
            if (perTweetType.count < self.numTweetsToKeep) {
                [perTweetType addObject:t];  // it lives
                [sparedUsers addObject:t.user];

                if (t.retweet) {
                    [sparedRetweets addObject:t.retweet];
                    [sparedUsers addObject:t.retweet.user];
                }
            } else
                [hitList addObject:t];  // it dies
        }
    }

    // delete all unneeded tweets
    for (Tweet * tweet in hitList) {
        if (![sparedRetweets containsObject:tweet]) {
            NSLog(@"Deleting tweet: '%@': '%@'", tweet.user.username,
                tweet.text);
            [context deleteObject:tweet];
        }
    }

    // now do a similar routine for dms

    // all users involved in a direct message must be spared
    [living removeAllObjects];
    [hitList removeAllObjects];

    NSArray * allDms =
        [[[DirectMessage findAll:context]
        sortedArrayUsingSelector:@selector(compare:)] arrayByReversingContents];

    for (DirectMessage * dm in allDms) {
        TwitterCredentials * c = dm.credentials;

        NSMutableArray * perCredentials = [living objectForKey:c.username];
        if (!perCredentials) {
            perCredentials = [NSMutableArray array];
            [living setObject:perCredentials forKey:c.username];
        }

        if (perCredentials.count < self.numDirectMessagesToKeep) {
            [perCredentials addObject:dm];
            [sparedUsers addObject:dm.recipient];
            [sparedUsers addObject:dm.sender];
        } else
            [context deleteObject:dm];
    }

    // delete all unneeded users
    NSArray * potentialVictims = [User findAll:context];
    for (User * user in potentialVictims)
        if (![sparedUsers containsObject:user]) {
            NSLog(@"Deleting user: '%@'.", user.username);
            [context deleteObject:user];
        }
}

@end
