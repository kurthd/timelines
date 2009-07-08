//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CheckCredentialsResponseProcessor.h"

@interface CheckCredentialsResponseProcessor ()

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, assign) id delegate;

@end

@implementation CheckCredentialsResponseProcessor

@synthesize credentials, delegate;

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                      delegate:(id)aDelegate
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
                 delegate:(id)aDelegate
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
    [self invokeSelector:sel withTarget:delegate args:credentials, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToValidateCredentials:error:);
    [self invokeSelector:sel withTarget:delegate args:credentials, error, nil];

    return YES;
}

@end
