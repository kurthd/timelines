//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountSettings : NSObject <NSCopying>
{
    NSNumber * pushMentions;
    NSNumber * pushDirectMessages;
}

- (BOOL)pushMentions;
- (void)setPushMentions:(BOOL)pushMentions;

- (BOOL)pushDirectMessages;
- (void)setPushDirectMessages:(BOOL)pushDirectMessages;

// returns all push settings masked together in an integer
- (NSNumber *)pushSettings;

- (BOOL)isEqualToSettings:(AccountSettings *)otherSettings;

+ (AccountSettings *)settingsForKey:(NSString *)key;
+ (void)setSettings:(AccountSettings *)settings
             forKey:(NSString *)key;
+ (void)deleteSettingsForKey:(NSString *)key;

@end
