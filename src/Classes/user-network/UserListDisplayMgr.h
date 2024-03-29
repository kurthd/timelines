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
#import "ContactCache.h"
#import "ContactMgr.h"

@class DisplayMgrHelper;

@interface UserListDisplayMgr :
    NSObject
    <UserListTableViewControllerDelegate, TwitterServiceDelegate,
    NetworkAwareViewControllerDelegate>
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

    DisplayMgrHelper * displayMgrHelper;

    TimelineDisplayMgr * timelineDisplayMgr;
    UserListDisplayMgr * nextUserListDisplayMgr;
    CredentialsActivatedPublisher * credentialsPublisher;
    TwitterCredentials * credentials;
    NSString * cursor;
    BOOL failedState;
    NSMutableDictionary * cache;
    BOOL alreadyBeenDisplayed;
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)navigationController
    userListController:(UserListTableViewController *)aUserListController
    service:(TwitterService *)service
    factory:(UserListDisplayMgrFactory *)userListFactory
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    showFollowing:(BOOL)showFollowing username:(NSString *)username
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
