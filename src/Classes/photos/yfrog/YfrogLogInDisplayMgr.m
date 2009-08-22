//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "YfrogLogInDisplayMgr.h"
#import "YfrogCredentials.h"
#import "YfrogCredentials+KeychainAdditions.h"

@interface YfrogLogInDisplayMgr ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@end

@implementation YfrogLogInDisplayMgr

@synthesize logInDisplayMgr;

- (void)dealloc
{
    self.logInDisplayMgr = nil;
    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext
{
    [super logInWithRootViewController:aController
                           credentials:someCredentials
                               context:aContext];

    LogInDisplayMgr * mgr =
        [[LogInDisplayMgr alloc]
        initWithRootViewController:aController managedObjectContext:aContext];

    mgr.allowsCancel = YES;
    mgr.delegate = self;
    [mgr setViewTitle:NSLocalizedString(@"yfrogloginview.view.title", @"")];
    [mgr setViewInstructions:
        NSLocalizedString(@"yfrogloginview.view.instructions", @"")];

    self.logInDisplayMgr = mgr;
    [mgr release];

    [self.logInDisplayMgr logInForUser:someCredentials.username animated:YES];
}

#pragma mark LogInDisplayMgrDelegate implementation

- (BOOL)isUsernameValid:(NSString *)username
{
    return YES;  // will always be the username from the supplied credentials
}

- (void)logInCompleted:(NSString *)username password:(NSString *)password
{
    YfrogCredentials * yfrogCredentials = (YfrogCredentials *)
    [NSEntityDescription insertNewObjectForEntityForName:@"YfrogCredentials"
                                  inManagedObjectContext:context];
    yfrogCredentials.username = username;
    [yfrogCredentials setPassword:password];
    yfrogCredentials.credentials = self.credentials;
    [self.context save:NULL];

    [self.delegate logInCompleted:yfrogCredentials];
}

- (void)logInCancelled
{
    [self.delegate logInCancelled];
}

@end
