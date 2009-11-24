//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface SendTweetResponseProcessor : ResponseProcessor
{
    NSString * text;

    CLLocationCoordinate2D * coordinate;

    NSNumber * referenceId;
    TwitterCredentials * credentials;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweet:(NSString *)someText
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate;
+ (id)processorWithTweet:(NSString *)someText
              coordinate:(CLLocationCoordinate2D)aCoordinate
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithTweet:(NSString *)someText
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithTweet:(NSString *)someText
         coordinate:(CLLocationCoordinate2D)aCoordinate
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
