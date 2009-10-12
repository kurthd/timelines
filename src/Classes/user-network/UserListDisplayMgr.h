//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "UserListTableViewControllerDelegate.h"
#import "NetworkAwareViewController.h"
#import "NetworkAwareViewControllerDelegate.h"
#import "UserListTableViewController.h"
#import "UserListTableViewController.h"
#import "UserListDisplayMgrFactory.h"
#import "TimelineDisplayMgrFactory.h"
#import "TwitterService.h"
#import "ComposeTweetDisplayMgr.h"
#import "SavedSearchMgr.h"
#import "TwitterCredentials.h"
#import "CredentialsActivatedPublisher.h"
#import "UserInfoViewController.h"
#import "TwitchBrowserViewController.h"
#import "PhotoBrowser.h"
#import "SavedSearchMgr.h"
#import "LocationMapViewController.h"
#import "LocationMapViewControllerDelegate.h"
#import "LocationInfoViewController.h"
#import "LocationInfoViewControllerDelegate.h"

@interface UserListDisplayMgr :
    NSObject
    <UserListTableViewControllerDelegate, TwitterServiceDelegate,
    UserInfoViewControllerDelegate, NetworkAwareViewControllerDelegate,
    LocationMapViewControllerDelegate, LocationInfoViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    UserListTableViewController * userListController;
    TwitterService * service;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    NSManagedObjectContext * context;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    SavedSearchMgr * findPeopleBookmarkMgr;
    BOOL showFollowing; // Screw polymorphism -- too much work
    NSString * username;

    TimelineDisplayMgr * timelineDisplayMgr;
    UserListDisplayMgr * nextUserListDisplayMgr;
    NetworkAwareViewController * nextWrapperController;
    CredentialsActivatedPublisher * credentialsPublisher;
    TwitterCredentials * credentials;
    NSString * cursor;
    BOOL failedState;
    NSMutableDictionary * cache;
    UserInfoViewController * userInfoController;
    BOOL alreadyBeenDisplayed;
    NSString * userInfoUsername;
    NSString * currentSearch;
    SavedSearchMgr * savedSearchMgr;

    LocationMapViewController * locationMapViewController;
    LocationInfoViewController * locationInfoViewController;
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    userListController:(UserListTableViewController *)aUserListController
    service:(TwitterService *)service
    factory:(UserListDisplayMgrFactory *)userListFactory
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    showFollowing:(BOOL)showFollowing username:(NSString *)username;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
