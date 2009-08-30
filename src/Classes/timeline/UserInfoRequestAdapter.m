//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoRequestAdapter.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "User.h"

@implementation UserInfoRequestAdapter

- (void)dealloc
{
    [target release];
    [wrapperController release];
    [errorHandler release];
    [super dealloc];
}

- (id)initWithTarget:(id)aTarget action:(SEL)anAction
    wrapperController:(NetworkAwareViewController *)aWrapperController
    errorHandler:(id)anErrorHandler
{
    if (self = [super init]) {
        target = [aTarget retain];
        action = anAction;
        wrapperController = [aWrapperController retain];
        errorHandler = [anErrorHandler retain];
    }

    return self;
}

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username
{
    NSLog(@"User info request adapter: setting user info for '%@'", username);
    [target performSelector:action withObject:user];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    if ([target
        respondsToSelector:@selector(failedToFetchUserInfoForUsername:error:)])
        [errorHandler
            performSelector:@selector(failedToFetchUserInfoForUsername:error:)
            withObject:username withObject:error];

    [wrapperController setCachedDataAvailable:NO];
    [wrapperController setUpdatingState:kDisconnected];
}

@end
