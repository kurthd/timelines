//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicLogInDisplayMgr.h"

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

- (void)logInCompleted:(TwitPicCredentials *)credentials
{
    [self.delegate logInCompleted:credentials];
}

- (void)logInCancelled
{
    [self.delegate logInCancelled];
}

@end
