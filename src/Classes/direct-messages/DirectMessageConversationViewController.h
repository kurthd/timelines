//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "DirectMessageConversationViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "RoundedImage.h"

@interface DirectMessageConversationViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    IBOutlet UIView * footerView;
    IBOutlet UIView * headerView;

    NSObject<DirectMessageConversationViewControllerDelegate> * delegate;

    NSArray * tweets;
    NSString * segregatedSenderUsername;

    NSMutableDictionary * alreadySent;
    NSArray * sortedTweetCache;
}

@property (nonatomic, assign)
    NSObject<DirectMessageConversationViewControllerDelegate> * delegate;

@property (nonatomic, retain) NSArray * sortedTweetCache;
@property (nonatomic, copy) NSString * segregatedSenderUsername;

- (void)setMessages:(NSArray *)messages;
- (void)addTweet:(DirectMessage *)tweet;
- (void)deleteTweet:(NSString *)tweetId;

@end
