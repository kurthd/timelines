//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserInfoViewControllerDelegate.h"
#import "LocationMapViewControllerDelegate.h"
#import "LocationInfoViewControllerDelegate.h"
#import "NetworkAwareViewController.h"
#import "LocationMapViewController.h"
#import "UserListDisplayMgr.h"
#import "TwitterCredentials.h"
#import "ComposeTweetDisplayMgr.h"
#import "TwitterService.h"
#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "CredentialsActivatedPublisher.h"
#import "SavedSearchMgr.h"
#import "LocationInfoViewController.h"

@interface DisplayMgrHelper :
    NSObject
    <UserInfoViewControllerDelegate, LocationMapViewControllerDelegate,
    LocationInfoViewControllerDelegate, TwitterServiceDelegate>
{
    NetworkAwareViewController * wrapperController;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    TwitterService * service;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    NSManagedObjectContext * context;
    SavedSearchMgr * findPeopleBookmarkMgr;

    TwitterCredentials * credentials;

    LocationMapViewController * locationMapViewController;
    LocationInfoViewController * locationInfoViewController;
    SavedSearchMgr * savedSearchMgr;
    UserInfoViewController * userInfoController;

    NetworkAwareViewController * userListNetAwareViewController;
    UserListDisplayMgr * userListDisplayMgr;
    NetworkAwareViewController * nextWrapperController;
    TimelineDisplayMgr * timelineDisplayMgr;
    CredentialsActivatedPublisher * credentialsPublisher;
    NSString * currentSearch;
    NSString * userInfoUsername;
}

- (id)initWithWrapperController:(NetworkAwareViewController *)wrapperCtrlr
    userListDisplayMgrFactor:(UserListDisplayMgrFactory *)userListDispMgrFctry
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    twitterService:(TwitterService *)service
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
