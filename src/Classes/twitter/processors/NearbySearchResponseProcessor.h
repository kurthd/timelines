//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface NearbySearchResponseProcessor : ResponseProcessor
{
    NSString * query;
    NSNumber * page;
    NSNumber * latitude;
    NSNumber * longitude;
    NSNumber * radius;
    NSNumber * radiusIsInMiles;
    id<TwitterServiceDelegate> delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithQuery:(NSString *)aQuery
                    page:(NSNumber *)aPage
                latitude:(NSNumber *)latitude
               longitude:(NSNumber *)longitude
                  radius:(NSNumber *)radius
         radiusIsInMiles:(NSNumber *)radiusIsInMiles
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithQuery:(NSString *)aQuery
               page:(NSNumber *)aPage
           latitude:(NSNumber *)latitude
          longitude:(NSNumber *)longitude
             radius:(NSNumber *)radius
    radiusIsInMiles:(NSNumber *)radiusIsInMiles
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
