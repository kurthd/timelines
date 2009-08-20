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
+ (NSString *)photoServiceNameKey;
+ (NSString *)videoServiceNameKey;
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
    [photoServiceName release];
    [videoServiceName release];
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
    [copy setPhotoServiceName:[self photoServiceName]];
    [copy setVideoServiceName:[self videoServiceName]];

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

- (NSString *)photoServiceName
{
    return photoServiceName;
}

- (void)setPhotoServiceName:(NSString *)name
{
    if (![photoServiceName isEqualToString:name]) {
        [photoServiceName release];
        photoServiceName = [name copy];
    }
}

- (NSString *)videoServiceName
{
    return videoServiceName;
}

- (void)setVideoServiceName:(NSString *)name
{
    if (![videoServiceName isEqualToString:name]) {
        [videoServiceName release];
        videoServiceName = [name copy];
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
    NSMutableDictionary * d =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
        pushMentions, [[self class] pushMentionsKey],
        pushDirectMessages, [[self class] pushDirectMessagesKey],
        nil];

    if ([self photoServiceName])
        [d setObject:[self photoServiceName]
              forKey:[[self class] photoServiceNameKey]];
    if ([self videoServiceName])
        [d setObject:[self videoServiceName]
              forKey:[[self class] videoServiceNameKey]];

    return d;
}

+ (id)fromDictionary:(NSDictionary *)dictionary
{
    AccountSettings * settings = [[[self class] alloc] init];

    settings->pushMentions =
        [[dictionary objectForKey:[[self class] pushMentionsKey]] retain];
    settings->pushDirectMessages =
        [[dictionary objectForKey:[[self class] pushDirectMessagesKey]] retain];

    NSString * photoService =
        [dictionary objectForKey:[[self class] photoServiceNameKey]];
    NSString * videoService =
        [dictionary objectForKey:[[self class] videoServiceNameKey]];

    [settings setPhotoServiceName:photoService];
    [settings setVideoServiceName:videoService];

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

+ (NSString *)photoServiceNameKey
{
    return @"photo-service";
}

+ (NSString *)videoServiceNameKey
{
    return @"vide-service";
}

+ (NSString *)allAccountSettingsKey
{
    return @"account-settings";
}

@end
