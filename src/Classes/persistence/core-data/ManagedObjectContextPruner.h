//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ManagedObjectContextPruner : NSObject
{
    NSManagedObjectContext * context;

    NSInteger numTweetsToKeep;
    NSInteger numMentionsToKeep;
    NSInteger numDirectMessagesToKeep;
}

@property (nonatomic, retain, readonly) NSManagedObjectContext * context;

@property (nonatomic, assign, readonly) NSInteger numTweetsToKeep;
@property (nonatomic, assign, readonly) NSInteger numMentionsToKeep;
@property (nonatomic, assign, readonly) NSInteger numDirectMessagesToKeep;

- (id)initWithContext:(NSManagedObjectContext *)aContext
      numTweetsToKeep:(NSInteger)numTweets
    numMentionsToKeep:(NSInteger)numMentions
         numDmsToKeep:(NSInteger)numDms;

- (void)pruneContext;

@end
