//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface MarkFavoriteResponseProcessor : ResponseProcessor
{
    NSString * tweetId;
    BOOL favorite;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweetId:(NSString *)aTweetId
                  favorite:(BOOL)isFavorite
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithTweetId:(NSString *)aTweetId
             favorite:(BOOL)isFavorite
              context:(NSManagedObjectContext *)aContext
             delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
