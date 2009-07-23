//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetDraftMgr.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface TweetDraftMgr ()

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation TweetDraftMgr

@synthesize context;

- (void)dealloc
{
    self.context = nil;
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init])
        self.context = aContext;

    return self;
}

- (TweetDraft *)tweetDraftForCredentials:(TwitterCredentials *)credentials
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        credentials.username];

    return [TweetDraft findFirst:predicate context:self.context];
}

- (BOOL)saveTweetDraft:(NSString *)text
           credentials:(TwitterCredentials *)credentials
                 error:(NSError **)error
{
    TweetDraft * draft = [self tweetDraftForCredentials:credentials];
    if (!draft) {
        draft = [TweetDraft createInstance:self.context];
        draft.credentials = credentials;
    }
    draft.text = text;

    *error = nil;
    return [self.context save:error];
}

- (BOOL)deleteTweetDraftForCredentials:(TwitterCredentials *)credentials
                                 error:(NSError **)error
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@", credentials.username];

    // either create a new one, or update the existing draft for this user
    NSArray * drafts = [TweetDraft findAll:predicate context:self.context];
    NSAssert1(drafts.count == 0 || drafts.count == 1,
        @"Expected either 0 or 1 drafts but found: %d.", drafts.count);

    if (drafts.count == 0)
        return NO;

    for (TweetDraft * draft in drafts)
        [self.context deleteObject:draft];

    *error = nil;
    return [self.context save:error];
}

- (DirectMessageDraft *)directMessageDraftForCredentials:(TwitterCredentials *)c
                                               recipient:(NSString *)recipient
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@ && recipient == %@",
        c.username, recipient];

    return [DirectMessageDraft findFirst:predicate context:self.context];
}

- (DirectMessageDraft *)directMessageDraftFromHomeScreenForCredentials:
    (TwitterCredentials *)credentials
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@ && fromHomeScreen == YES",
        credentials.username];

    return [DirectMessageDraft findFirst:predicate context:self.context];
}

- (BOOL)saveDirectMessageDraftFromHomeScreen:(NSString *)text
                                   recipient:(NSString *)recipient
                                 credentials:(TwitterCredentials *)credentials
                                       error:(NSError **)error
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@ && fromHomeScreen == YES",
        credentials.username];

    // either create a new one, or update the existing draft for this user
    DirectMessageDraft * draft =
        [DirectMessageDraft findFirst:predicate context:self.context];
    if (!draft)
        draft = [DirectMessageDraft createInstance:self.context];

    draft.recipient = recipient;
    draft.credentials = credentials;
    draft.text = text;
    draft.fromHomeScreen = [NSNumber numberWithBool:YES];

    *error = nil;
    return [self.context save:error];
}

- (BOOL)saveDirectMessageDraft:(NSString *)text
                     recipient:(NSString *)recipient
                   credentials:(TwitterCredentials *)credentials
                         error:(NSError **)error
{
    // either create a new one, or update the existing draft for this user
    DirectMessageDraft * draft =
        [self directMessageDraftForCredentials:credentials
                                     recipient:recipient];
    if (!draft)
        draft = [DirectMessageDraft createInstance:self.context];

    draft.recipient = recipient;
    draft.credentials = credentials;
    draft.text = text;
    draft.fromHomeScreen = [NSNumber numberWithBool:NO];

    *error = nil;
    return [self.context save:error];
}

- (BOOL)deleteDirectMessageDraftForRecipient:(NSString *)recipient
                                 credentials:(TwitterCredentials *)credentials
                                       error:(NSError **)error
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@ && recipient == %@",
        credentials.username, recipient];

    // either create a new one, or update the existing draft for this user
    DirectMessageDraft * draft = [DirectMessageDraft findFirst:predicate
                                                       context:self.context];

    *error = nil;
    if (draft) {
        [self.context deleteObject:draft];
        return [self.context save:error];
    }

    return NO;
}

- (BOOL)deleteDirectMessageDraftFromHomeScreenForCredentials:
    (TwitterCredentials *)credentials
    error:(NSError **)error
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@ && fromHomeScreen == YES",
        credentials.username];

    // either create a new one, or update the existing draft for this user
    DirectMessageDraft * draft = [DirectMessageDraft findFirst:predicate
                                                       context:self.context];

    *error = nil;
    if (draft) {
        [self.context deleteObject:draft];
        return [self.context save:error];
    }

    return NO;
}

- (BOOL)deleteAllDirectMessageDraftsForCredentials:(TwitterCredentials *)c
                                             error:(NSError **)error
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"credentials.username == %@", c.username];

    // either create a new one, or update the existing draft for this user
    NSArray * drafts = [DirectMessageDraft findAll:predicate
                                           context:self.context];

    if (drafts.count == 0)
        return NO;

    for (DirectMessageDraft * draft in drafts)
        [self.context deleteObject:draft];

    *error = nil;
    return [self.context save:error];
}

@end
