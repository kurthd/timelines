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
#import "LocationMapViewController.h"
#import "LocationMapViewControllerDelegate.h"
#import "CredentialsActivatedPublisher.h"
#import "SavedSearchMgr.h"
#import "RecentSearchMgr.h"

@interface ProfileDisplayMgr :
    NSObject <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    UserInfoViewControllerDelegate, LocationMapViewControllerDelegate,
    LocationInfoViewControllerDelegate>
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

    NetworkAwareViewController * nextWrapperController;
    TimelineDisplayMgr * timelineDisplayMgr;
    CredentialsActivatedPublisher * credentialsPublisher;
    UserListDisplayMgr * nextUserListDisplayMgr;

    BOOL freshProfile;
    NSString * username;

    LocationMapViewController * locationMapViewController;
    LocationInfoViewController * locationInfoViewController;

    NSString * currentSearch; // mention search value
    SavedSearchMgr * generalSavedSearchMgr;
    RecentSearchMgr * recentSearchMgr;

    UIBarButtonItem * updatingProfileActivityView;
    UIBarButtonItem * refreshButton;
}

@property (nonatomic, retain) UIBarButtonItem * refreshButton;
@property (nonatomic, retain) UINavigationController * navigationController;

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)userInfoController
    service:(TwitterService *)service context:(NSManagedObjectContext *)aContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    navigationController:(UINavigationController *)navigationController;

- (void)setNewProfileUsername:(NSString *)username user:(User *)user;
- (void)refreshProfile;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
