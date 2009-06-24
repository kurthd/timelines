//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "CredentialsSetChangedPublisher.h"

@interface CredentialsSetChangedPublisher ()

@property (nonatomic, assign) id listener;
@property (nonatomic, assign) SEL action;

@end

@implementation CredentialsSetChangedPublisher

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
    id credentials = [info objectForKey:@"credentials"];
    id added = [info objectForKey:@"added"];

    [self.listener performSelector:self.action
                        withObject:credentials
                        withObject:added];
}

#pragma mark Subscribing for notifications

- (NSString *)notificationName
{
    return @"CredentialsSetChangedNotification";
}

@end
