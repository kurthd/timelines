//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitVidLogInDisplayMgr.h"
#import "TwitVidCredentials.h"
#import "TwitVidCredentials+KeychainAdditions.h"

@interface TwitVidLogInDisplayMgr ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@end

@implementation TwitVidLogInDisplayMgr

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
    TwitVidCredentials * twitVidCredentials = (TwitVidCredentials *)
    [NSEntityDescription insertNewObjectForEntityForName:@"TwitVidCredentials"
                                  inManagedObjectContext:context];
    twitVidCredentials.username = username;
    [twitVidCredentials setPassword:password];
    twitVidCredentials.credentials = self.credentials;
    [self.context save:NULL];

    [self.delegate logInCompleted:twitVidCredentials];
}

- (void)logInCancelled
{
    [self.delegate logInCancelled];
}

@end
