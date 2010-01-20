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

+ (NSNumber *)pushMentionsDefaultValue;
+ (NSNumber *)pushDirectMessagesDefaultValue;
+ (PushNotificationSound *)pushNotificationSoundDefaultValue;
+ (NSNumber *)didPromptToEnableGeotaggingDefaultValue;
+ (NSNumber *)geotagTweetsDefaultValue;

+ (NSString *)pushMentionsKey;
+ (NSString *)pushDirectMessagesKey;
+ (NSString *)pushNotificationSoundNameKey;
+ (NSString *)pushNotificationSoundFileKey;
+ (NSString *)photoServiceNameKey;
+ (NSString *)videoServiceNameKey;
+ (NSString *)allAccountSettingsKey;
+ (NSString *)didPromptToEnableGeotaggingKey;
+ (NSString *)geotagTweetsKey;

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
    [pushNotificationSound release];
    [photoServiceName release];
    [videoServiceName release];
    [geotagTweets release];
    [didPromptToEnableGeotagging release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        pushMentions = [[[self class] pushMentionsDefaultValue] retain];
        pushDirectMessages =
            [[[self class] pushDirectMessagesDefaultValue] retain];
        pushNotificationSound =
            [[[self class] pushNotificationSoundDefaultValue] retain];
        geotagTweets = [[[self class] geotagTweetsDefaultValue] retain];
        didPromptToEnableGeotagging =
            [[[self class] didPromptToEnableGeotaggingDefaultValue] retain];
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
    [copy setPushNotificationSound:[self pushNotificationSound]];
    [copy setPhotoServiceName:[self photoServiceName]];
    [copy setVideoServiceName:[self videoServiceName]];
    [copy setDidPromptToEnableGeotagging:[self didPromptToEnableGeotagging]];
    [copy setGeotagTweets:[self geotagTweets]];

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

- (PushNotificationSound *)pushNotificationSound
{
    return pushNotificationSound;
}

- (void)setPushNotificationSound:(PushNotificationSound *)aSound
{
    [pushNotificationSound release];
    pushNotificationSound = [aSound copy];
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

- (BOOL)didPromptToEnableGeotagging
{
    return [didPromptToEnableGeotagging boolValue];
}

- (void)setDidPromptToEnableGeotagging:(BOOL)didPrompt
{
    if ([self didPromptToEnableGeotagging] != didPrompt) {
        [didPromptToEnableGeotagging release];
        didPromptToEnableGeotagging = [[NSNumber alloc] initWithBool:didPrompt];
    }
}

- (BOOL)geotagTweets
{
    return [geotagTweets boolValue];
}

- (void)setGeotagTweets:(BOOL)geotag
{
    if ([self geotagTweets] != geotag) {
        [geotagTweets release];
        geotagTweets = [[NSNumber alloc] initWithBool:geotag];
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

- (BOOL)pushSettingsAreEqualToPushSettings:(AccountSettings *)otherSettings
{
    return
        [self pushMentions] == [otherSettings pushMentions] &&
        [self pushDirectMessages] == [otherSettings pushDirectMessages] &&
        [[self pushNotificationSound] isEqualToSound:
            [otherSettings pushNotificationSound]];
}

#pragma mark Converting from and to an NSDictionary

- (NSDictionary *)toDictionary
{
    NSMutableDictionary * d =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
        pushMentions, [[self class] pushMentionsKey],
        pushDirectMessages, [[self class] pushDirectMessagesKey],

        pushNotificationSound.name, [[self class] pushNotificationSoundNameKey],
        pushNotificationSound.file, [[self class] pushNotificationSoundFileKey],

        didPromptToEnableGeotagging,
            [[self class] didPromptToEnableGeotaggingKey],
        geotagTweets, [[self class] geotagTweetsKey],
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

    NSString * soundName =
        [dictionary objectForKey:[[self class] pushNotificationSoundNameKey]];
    NSString * soundFile =
        [dictionary objectForKey:[[self class] pushNotificationSoundFileKey]];

    settings->pushNotificationSound =
        !soundName || !soundFile ?
        [[PushNotificationSound defaultSound] retain] :
        [[PushNotificationSound alloc] initWithName:soundName file:soundFile];

    NSNumber * didPrompt =
        [dictionary objectForKey:[[self class] didPromptToEnableGeotaggingKey]];
    if (!didPrompt)
        didPrompt = [[self class] didPromptToEnableGeotaggingDefaultValue];
    settings->didPromptToEnableGeotagging = [didPrompt retain];

    NSNumber * geotag =
        [dictionary objectForKey:[[self class] geotagTweetsKey]];
    if (!geotag)
        geotag = [[self class] geotagTweetsDefaultValue];
    settings->geotagTweets = [geotag retain];

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

#pragma mark Settings default values

+ (NSNumber *)pushMentionsDefaultValue
{
    return [NSNumber numberWithBool:YES];
}

+ (NSNumber *)pushDirectMessagesDefaultValue
{
    return [NSNumber numberWithBool:YES];
}

+ (PushNotificationSound *)pushNotificationSoundDefaultValue
{
    return [PushNotificationSound tritoneSound];
}

+ (NSNumber *)didPromptToEnableGeotaggingDefaultValue
{
    return [NSNumber numberWithBool:NO];
}

+ (NSNumber *)geotagTweetsDefaultValue
{
    return [NSNumber numberWithBool:NO];
}

#pragma mark Settings key values

+ (NSString *)pushMentionsKey
{
    return @"push-mentions";
}

+ (NSString *)pushDirectMessagesKey
{
    return @"push-direct-messages";
}

+ (NSString *)pushNotificationSoundNameKey
{
    return @"push-sound-name";
}

+ (NSString *)pushNotificationSoundFileKey
{
    return @"push-sound-file";
}

+ (NSString *)photoServiceNameKey
{
    return @"photo-service";
}

+ (NSString *)videoServiceNameKey
{
    return @"video-service";
}

+ (NSString *)allAccountSettingsKey
{
    return @"account-settings";
}

+ (NSString *)didPromptToEnableGeotaggingKey
{
    return @"did-prompt-to-enable-geotagging";
}

+ (NSString *)geotagTweetsKey
{
    return @"geotag-tweets";
}

@end
