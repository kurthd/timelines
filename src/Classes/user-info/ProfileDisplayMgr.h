//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "UserInfoViewController.h"
#import "TwitterService.h"
#import "UserListDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "UserListDisplayMgrFactory.h"
#import "ComposeTweetDisplayMgr.h"
#import "NetworkAwareViewControllerDelegate.h"
#import "TwitterServiceDelegate.h"
#import "UserInfoViewControllerDelegate.h"

@interface ProfileDisplayMgr :
    NSObject <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    UserInfoViewControllerDelegate>
{
    NetworkAwareViewController * netAwareController;
    UserInfoViewController * userInfoController;
    TwitterService * service;
    UserListDisplayMgr * userListDisplayMgr;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;
    NSManagedObjectContext * context;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    UINavigationController * navigationController;

    TwitterCredentials * credentials;
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)userInfoController
    service:(TwitterService *)service context:(NSManagedObjectContext *)aContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    navigationController:(UINavigationController *)navigationController;

- (void)refreshProfile;
- (void)setCredentials:(TwitterCredentials *)credentials;

@end
