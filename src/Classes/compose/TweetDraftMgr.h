//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "TweetDraft.h"
#import "DirectMessageDraft.h"

@class NSManagedObjectContext;

@interface TweetDraftMgr : NSObject
{
    NSManagedObjectContext * context;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext;

- (TweetDraft *)tweetDraftForCredentials:(TwitterCredentials *)credentials;
- (BOOL)saveTweetDraft:(NSString *)text
           credentials:(TwitterCredentials *)credentials
                 error:(NSError **)error;
- (BOOL)saveTweetDraft:(NSString *)text
           credentials:(TwitterCredentials *)credentials
      inReplyToTweetId:(NSNumber *)tweetId
     inReplyToUsername:(NSString *)username
                 error:(NSError **)error;
- (BOOL)deleteTweetDraftForCredentials:(TwitterCredentials *)credentials
                                 error:(NSError **)error;

- (DirectMessageDraft *)directMessageDraftForCredentials:(TwitterCredentials *)c
                                               recipient:(NSString *)recipient;
- (DirectMessageDraft *)directMessageDraftFromHomeScreenForCredentials:
    (TwitterCredentials *)credentials;

- (BOOL)saveDirectMessageDraftFromHomeScreen:(NSString *)text
                                   recipient:(NSString *)recipient
                                 credentials:(TwitterCredentials *)credentials
                                       error:(NSError **)error;
- (BOOL)saveDirectMessageDraft:(NSString *)text
                     recipient:(NSString *)recipient
                   credentials:(TwitterCredentials *)credentials
                         error:(NSError **)error;
- (BOOL)deleteDirectMessageDraftForRecipient:(NSString *)recipient
                                 credentials:(TwitterCredentials *)credentials
                                       error:(NSError **)error;
- (BOOL)deleteDirectMessageDraftFromHomeScreenForCredentials:
    (TwitterCredentials *)credentials
    error:(NSError **)error;
- (BOOL)deleteAllDirectMessageDraftsForCredentials:(TwitterCredentials *)c
                                             error:(NSError **)error;

@end
