//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PosterousLogInDisplayMgr.h"
#import "PosterousCredentials.h"
#import "PosterousCredentials+KeychainAdditions.h"
#import "TwitbitShared.h"

@interface PosterousLogInDisplayMgr ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@end

@implementation PosterousLogInDisplayMgr

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
    [mgr setViewTitle:LS(@"posterousloginview.view.title")];
    [mgr setViewInstructions:LS(@"posterousloginview.view.instructions")];

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
    PosterousCredentials * creds = (PosterousCredentials *)
    [NSEntityDescription insertNewObjectForEntityForName:@"PosterousCredentials"
                                  inManagedObjectContext:context];
    creds.username = username;
    [creds setPassword:password];
    creds.credentials = self.credentials;
    [self.context save:NULL];

    [self.delegate logInCompleted:creds];
}

- (void)logInCancelled
{
    [self.delegate logInCancelled];
}

@end
