//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicLogInDisplayMgr.h"
#import "TwitPicCredentials.h"
#import "TwitPicCredentials+KeychainAdditions.h"

@interface TwitPicLogInDisplayMgr ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;

@end

@implementation TwitPicLogInDisplayMgr

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
    [mgr setViewTitle:NSLocalizedString(@"twitpicloginview.view.title", @"")];
    [mgr setViewInstructions:
        NSLocalizedString(@"twitpicloginview.view.instructions", @"")];

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
    TwitPicCredentials * twitPicCredentials = (TwitPicCredentials *)
    [NSEntityDescription insertNewObjectForEntityForName:@"TwitPicCredentials"
                                  inManagedObjectContext:context];
    twitPicCredentials.username = username;
    [twitPicCredentials setPassword:password];
    twitPicCredentials.credentials = self.credentials;
    [self.context save:NULL];

    [self.delegate logInCompleted:twitPicCredentials];
}

- (void)logInCancelled
{
    [self.delegate logInCancelled];
}

@end
