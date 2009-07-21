//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsChangedPublisher.h"

@interface AccountSettingsChangedPublisher ()

@property (nonatomic, assign) id listener;
@property (nonatomic, assign) SEL action;

+ (NSString *)accountKey;
+ (NSString *)settingsKey;

@end

@implementation AccountSettingsChangedPublisher

@synthesize listener, action;

+ (id)publisherWithListener:(id)aListener action:(SEL)anAction
{
    id obj = [[[self class] alloc] initWithListener:aListener action:anAction];
    return [obj autorelease];
}

- (void)dealloc
{
    self.listener = nil;
    self.action = nil;
    [super dealloc];
}

- (id)initWithListener:(id)aListener action:(SEL)anAction
{
    if (self = [super initWithListener:aListener action:anAction]) {
        self.listener = aListener;
        self.action = anAction;
    }

    return self;
}

#pragma mark Receiving notifications

- (void)notificationReceived:(NSNotification *)notification
{
    NSDictionary * info = notification.userInfo;

    // Don't use super class implementation as credentials may be nil in the
    // case of a log out.
    id settings = [info objectForKey:[[self class] settingsKey]];
    id account = [info objectForKey:[[self class] accountKey]];

    [self.listener performSelector:self.action
                        withObject:settings
                        withObject:account];
}

#pragma mark Helper methods

+ (void)publishAccountSettingsChanged:(AccountSettings *)changedSettings
                           forAccount:(NSString *)account
{
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        changedSettings, [[self class] settingsKey],
        account, [[self class] accountKey],
        nil];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:[[self class] notificationName]
                      object:self
                    userInfo:userInfo];
    
}

+ (NSString *)notificationName
{
    return @"AccountSettingsChangedChangedNotification";
}

+ (NSString *)accountKey
{
    return @"account";
}

+ (NSString *)settingsKey
{
    return @"settings";
}

@end
