//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountSettings : NSObject <NSCopying>
{
    NSNumber * pushMentions;
    NSNumber * pushDirectMessages;

    NSString * photoServiceName;
    NSString * videoServiceName;

    NSNumber * geotagTweets;
}

- (BOOL)pushMentions;
- (void)setPushMentions:(BOOL)pushMentions;

- (BOOL)pushDirectMessages;
- (void)setPushDirectMessages:(BOOL)pushDirectMessages;

- (NSString *)photoServiceName;
- (void)setPhotoServiceName:(NSString *)name;

- (NSString *)videoServiceName;
- (void)setVideoServiceName:(NSString *)name;

- (BOOL)geotagTweets;
- (void)setGeotagTweets:(BOOL)geotag;

// returns all push settings masked together in an integer
- (NSNumber *)pushSettings;

- (BOOL)isEqualToSettings:(AccountSettings *)otherSettings;

+ (AccountSettings *)settingsForKey:(NSString *)key;
+ (void)setSettings:(AccountSettings *)settings
             forKey:(NSString *)key;
+ (void)deleteSettingsForKey:(NSString *)key;

@end
