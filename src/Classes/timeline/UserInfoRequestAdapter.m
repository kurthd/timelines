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
    [super dealloc];
}

- (id)initWithTarget:(id)aTarget action:(SEL)anAction
    wrapperController:(NetworkAwareViewController *)aWrapperController
{
    if (self = [super init]) {
        target = [aTarget retain];
        action = anAction;
        wrapperController = [aWrapperController retain];
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
    NSString * message = error.localizedDescription;
    NSString * title =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchuserinfo", @"");
    UIAlertView * alertView =
        [UIAlertView simpleAlertViewWithTitle:title message:message];
    [alertView show];

    [wrapperController setCachedDataAvailable:NO];
    [wrapperController setUpdatingState:kDisconnected];
}

@end
