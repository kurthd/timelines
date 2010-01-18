//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PushNotificationSound.h"

@interface AccountSettings : NSObject <NSCopying>
{
    NSNumber * pushMentions;
    NSNumber * pushDirectMessages;

    PushNotificationSound * pushNotificationSound;

    NSString * photoServiceName;
    NSString * videoServiceName;

    NSNumber * didPromptToEnableGeotagging;
    NSNumber * geotagTweets;
}

- (BOOL)pushMentions;
- (void)setPushMentions:(BOOL)pushMentions;

- (BOOL)pushDirectMessages;
- (void)setPushDirectMessages:(BOOL)pushDirectMessages;

- (PushNotificationSound *)pushNotificationSound;
- (void)setPushNotificationSound:(PushNotificationSound *)aSound;

- (NSString *)photoServiceName;
- (void)setPhotoServiceName:(NSString *)name;

- (NSString *)videoServiceName;
- (void)setVideoServiceName:(NSString *)name;

- (BOOL)didPromptToEnableGeotagging;
- (void)setDidPromptToEnableGeotagging:(BOOL)didPrompt;

- (BOOL)geotagTweets;
- (void)setGeotagTweets:(BOOL)geotag;

// returns all push settings masked together in an integer
- (NSNumber *)pushSettings;

- (BOOL)pushSettingsAreEqualToPushSettings:(AccountSettings *)otherSettings;

+ (AccountSettings *)settingsForKey:(NSString *)key;
+ (void)setSettings:(AccountSettings *)settings
             forKey:(NSString *)key;
+ (void)deleteSettingsForKey:(NSString *)key;

@end
