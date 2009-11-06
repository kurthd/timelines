//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationViewController.h"
#import "TwitterService.h"
#import "Tweet.h"

@protocol ConversationDisplayMgrDelegate

- (void)displayTweetFromConversation:(Tweet *)tweet;

@end

@interface ConversationDisplayMgr :
    NSObject <ConversationViewControllerDelegate, TwitterServiceDelegate>
{
    id<ConversationDisplayMgrDelegate> delegate;

    TwitterService * service;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    ConversationViewController * conversationViewController;

    // TODO: Subscribe for credentials changing notifications
}

@property (nonatomic, assign) id<ConversationDisplayMgrDelegate> delegate;

- (id)initWithTwitterService:(TwitterService *)aService
                     context:(NSManagedObjectContext *)aContext;

- (void)displayConversationFrom:(NSString *)aFirstTweetId
           navigationController:(UINavigationController *)navController;

@end
