//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchTimelineResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSNumber * updateId;
    NSNumber * page;
    NSNumber * count;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;
+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                   username:(NSString *)ausername
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;
- (id)initWithUpdateId:(NSNumber *)anUpdateId
              username:(NSString *)ausername
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
