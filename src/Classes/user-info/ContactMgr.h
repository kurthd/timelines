//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/ABNewPersonViewController.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import "ContactCacheSetter.h"

@interface ContactMgr :
    NSObject
    <ABNewPersonViewControllerDelegate, UIActionSheetDelegate,
    ABPeoplePickerNavigationControllerDelegate>
{
    UIViewController * tabViewController;
    NSObject<ContactCacheSetter> * contactCacheSetter;

    ABRecordRef contactToAdd;
    NSString * username;
}

@property (nonatomic) ABRecordRef contactToAdd;
@property (nonatomic, copy) NSString * username;

- (id)initWithTabBarController:(UIViewController *)tabBarController
    contactCacheSetter:(NSObject<ContactCacheSetter> *)contactCacheSetter;

- (void)userDidAddContact:(ABRecordRef)person forUser:(NSString *)aUsername;

@end
