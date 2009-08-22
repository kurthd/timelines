//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterBasicAuthAuthenticator.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@interface TwitterBasicAuthAuthenticator ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

@property (nonatomic, retain) MGTwitterEngine * twitter;

@end

@implementation TwitterBasicAuthAuthenticator

@synthesize username, password;
@synthesize delegate, twitter;

- (void)dealloc
{
    self.delegate = nil;

    self.username = nil;
    self.password = nil;

    self.twitter = nil;

    [super dealloc];
}

- (id)init
{
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<TwitterBasicAuthAuthenticatorDelegate>)aDelegate
{
    if (self = [super init]) {
        self.delegate = aDelegate;
        twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
    }

    return self;
}

#pragma mark Public implementation

- (void)authenticateUsername:(NSString *)user password:(NSString *)pass
{
    self.username = user;
    self.password = pass;

    [self.twitter setUsername:self.username password:self.password];
    [self.twitter checkUserCredentials];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

#pragma mark MGTwitterEngineDelegate implementation

- (void)requestSucceeded:(NSString *)requestIdentifier
{
    // authentication succeeded
    [self.delegate authenticator:self
         didAuthenticateUsername:self.username
                        password:self.password];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    // authentication failed
    [self.delegate authenticator:self
        didFailToAuthenticateUsername:self.username
                             password:self.password
                                error:error];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)connectionFinished
{
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{
}

- (void)directMessagesReceived:(NSArray *)messages
                    forRequest:(NSString *)identifier
{
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
}

- (void)imageReceived:(UIImage *)image forRequest:(NSString *)identifier
{
}

- (void)searchResultsReceived:(NSArray *)searchResults
                   forRequest:(NSString *)connectionIdentifier
{
}

- (void)receivedObject:(NSDictionary *)dictionary
            forRequest:(NSString *)connectionIdentifier
{
}

@end
