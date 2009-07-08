//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface MarkFavoriteResponseProcessor : ResponseProcessor
{
    NSString * tweetId;
    BOOL favorite;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweetId:(NSString *)aTweetId
                  favorite:(BOOL)isFavorite
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate;

- (id)initWithTweetId:(NSString *)aTweetId
             favorite:(BOOL)isFavorite
              context:(NSManagedObjectContext *)aContext
             delegate:(id)aDelegate;

@end
