//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "PhotoServiceCredentials.h"

@protocol PhotoServiceLogInDisplayMgrDelegate

- (void)logInCompleted:(PhotoServiceCredentials *)credentials;
- (void)logInCancelled;

@end

@interface PhotoServiceLogInDisplayMgr : NSObject
{
    id<PhotoServiceLogInDisplayMgrDelegate> delegate;
}

@property (nonatomic, assign) id<PhotoServiceLogInDisplayMgrDelegate> delegate;

+ (id)logInDisplayMgrWithServiceName:(NSString *)serviceName;

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext;

@end
