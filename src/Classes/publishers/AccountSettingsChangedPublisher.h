//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractUpdatePublisher.h"
#import "AccountSettings.h"

@interface AccountSettingsChangedPublisher : AbstractUpdatePublisher
{
    id listener;
    SEL action;
}

//
// The selector provided should have the same arguments as:
//   - (void)accountSettingsChanged:(AccountSettings *)changedSettings
//                       forAccount:(NSString *)account
//
+ (id)publisherWithListener:(id)aListener action:(SEL)anAction;
- (id)initWithListener:(id)aListener action:(SEL)anAction;

#pragma mark Helper methods

+ (void)publishAccountSettingsChanged:(AccountSettings *)changedSettings
                           forAccount:(NSString *)account;

+ (NSString *)notificationName;

@end
