//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "QueryIsFollowingResponseProcessor.h"

@interface QueryIsFollowingResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * followee;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation QueryIsFollowingResponseProcessor

@synthesize username, followee, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                   followee:(NSString *)aFollowee
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                           followee:aFollowee
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.followee = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername
              followee:(NSString *)aFollowee
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.followee = aFollowee;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)infos
{
    if (!infos)
        return NO;

    NSAssert1(infos.count == 1, @"Expected one element in response to "
        "following query but received '%d'.", infos.count);

    id value = [[infos objectAtIndex:0] objectForKey:@"friends"];
    BOOL following = [value boolValue];

    SEL sel = following ? @selector(user:isFollowing:) :
                          @selector(user:isNotFollowing:);
    if ([delegate respondsToSelector:sel])
        [delegate performSelector:sel withObject:username withObject:followee];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToQueryIfUser:isFollowing:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToQueryIfUser:username
                          isFollowing:followee
                                error:error];

    return YES;
}

@end
