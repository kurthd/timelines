//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CheckCredentialsResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface CheckCredentialsResponseProcessor ()

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation CheckCredentialsResponseProcessor

@synthesize credentials, delegate;

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                      delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithCredentials:someCredentials
                                              delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.credentials = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                 delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.credentials = someCredentials;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(id)response
{
    SEL sel = @selector(credentialsValidated:);
    if ([delegate respondsToSelector:sel])
        [delegate credentialsValidated:credentials];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToValidateCredentials:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToValidateCredentials:credentials error:error];

    return YES;
}

@end
