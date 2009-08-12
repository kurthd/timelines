//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettings.h"

enum PushSettings
{
    kPushMentions = 1,
    kPushDirectMessages = kPushMentions << 1
};

@interface AccountSettings ()

- (NSDictionary *)toDictionary;
+ (id)fromDictionary:(NSDictionary *)dictionary;
+ (NSMutableDictionary *)allAccountSettings;
+ (void)setAllAccountSettings:(NSDictionary *)allAccountSettings;

+ (NSString *)pushMentionsKey;
+ (NSString *)pushDirectMessagesKey;
+ (NSString *)allAccountSettingsKey;

@end

@implementation AccountSettings

+ (AccountSettings *)defaultSettings
{
    return [[[[self class] alloc] init] autorelease];
}

+ (AccountSettings *)settingsForKey:(NSString *)key
{
    NSMutableDictionary * allAccountSettings =
        [[self class] allAccountSettings];

    NSDictionary * settingsDictionary = [allAccountSettings objectForKey:key];

    AccountSettings * settings = nil;
    if (settingsDictionary)
        settings = [[self class] fromDictionary:settingsDictionary];
    else {
        settings = [[self class] defaultSettings];
        [self setSettings:settings forKey:key];
    }

    return settings;
}

+ (void)setSettings:(AccountSettings *)settings
             forKey:(NSString *)key
{
    NSDictionary * d = [settings toDictionary];

    NSMutableDictionary * allAccountSettings =
        [[self class] allAccountSettings];
    [allAccountSettings setObject:d forKey:key];

    [[self class] setAllAccountSettings:allAccountSettings];
}

+ (void)deleteSettingsForKey:(NSString *)key
{
    NSMutableDictionary * allAccountSettings =
        [[self class] allAccountSettings];
    [allAccountSettings removeObjectForKey:key];

    [[self class] setAllAccountSettings:allAccountSettings];
}

- (void)dealloc
{
    [pushMentions release];
    [pushDirectMessages release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        pushMentions = [[NSNumber alloc] initWithBool:YES];
        pushDirectMessages = [[NSNumber alloc] initWithBool:YES];
    }

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"push mentions: %@, push direct "
        "messages: %@", [self pushMentions] ? @"yes" : @"no",
        [self pushDirectMessages] ? @"yes" : @"no"];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    AccountSettings * copy = [[[self class] allocWithZone:zone] init];

    [copy setPushMentions:[self pushMentions]];
    [copy setPushDirectMessages:[self pushDirectMessages]];

    return copy;
}

#pragma mark Accessors

- (BOOL)pushMentions
{
    return [pushMentions boolValue];
}

- (void)setPushMentions:(BOOL)b
{
    if ([pushMentions boolValue] != b) {
        [pushMentions release];
        pushMentions = [[NSNumber alloc] initWithBool:b];
    }
}

- (BOOL)pushDirectMessages
{
    return [pushDirectMessages boolValue];
}

- (void)setPushDirectMessages:(BOOL)b
{
    if ([pushDirectMessages boolValue] != b) {
        [pushDirectMessages release];
        pushDirectMessages = [[NSNumber alloc] initWithBool:b];
    }
}

- (NSNumber *)pushSettings
{
    NSInteger n = 0;

    if ([self pushMentions])
        n |= kPushMentions;
    if ([self pushDirectMessages])
        n |= kPushDirectMessages;

    return [NSNumber numberWithInteger:n];
}

- (BOOL)isEqualToSettings:(AccountSettings *)otherSettings
{
    return
        [self pushMentions] == [otherSettings pushMentions] &&
        [self pushDirectMessages] == [otherSettings pushDirectMessages];
}

#pragma mark Converting from and to an NSDictionary

- (NSDictionary *)toDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        pushMentions, [[self class] pushMentionsKey],
        pushDirectMessages, [[self class] pushDirectMessagesKey],
        nil];
}

+ (id)fromDictionary:(NSDictionary *)dictionary
{
    AccountSettings * settings = [[[self class] alloc] init];

    settings->pushMentions =
        [[dictionary objectForKey:[[self class] pushMentionsKey]] retain];
    settings->pushDirectMessages =
        [[dictionary objectForKey:[[self class] pushDirectMessagesKey]] retain];

    return [settings autorelease];
}

+ (NSMutableDictionary *)allAccountSettings
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary * allAccountSettings =
        [[defaults objectForKey:[[self class] allAccountSettingsKey]]
        mutableCopy];

    return allAccountSettings ?
        [allAccountSettings autorelease] : [NSMutableDictionary dictionary];
}

+ (void)setAllAccountSettings:(NSDictionary *)allAccountSettings
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:allAccountSettings
                 forKey:[[self class] allAccountSettingsKey]];

    [defaults synchronize];
}

+ (NSString *)pushMentionsKey
{
    return @"push-mentions";
}

+ (NSString *)pushDirectMessagesKey
{
    return @"push-direct-messages";
}

+ (NSString *)allAccountSettingsKey
{
    return @"account-settings";
}

@end
