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

    UIViewController * rootViewController;
    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<PhotoServiceLogInDisplayMgrDelegate> delegate;

@property (nonatomic, retain, readonly) UIViewController * rootViewController;
@property (nonatomic, retain, readonly) TwitterCredentials * credentials;
@property (nonatomic, retain, readonly) NSManagedObjectContext * context;

+ (id)logInDisplayMgrWithServiceName:(NSString *)serviceName;

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext;

@end
