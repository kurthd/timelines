//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogInDisplayMgr.h"
#import "TwitterCredentials.h"
#import "PhotoServiceLogInDisplayMgr.h"

@interface PosterousLogInDisplayMgr :
    PhotoServiceLogInDisplayMgr <LogInDisplayMgrDelegate>
{
    LogInDisplayMgr * logInDisplayMgr;
}

- (id)init;

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext;

@end
