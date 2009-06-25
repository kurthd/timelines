//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "QueryIsFollowingResponseProcessor.h"

@interface QueryIsFollowingResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * followee;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation QueryIsFollowingResponseProcessor

@synthesize username, followee, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                   followee:(NSString *)aFollowee
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
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
              delegate:(id)aDelegate
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
    BOOL following = value && [value isEqualToString:@"true"];

    SEL sel = following ? @selector(user:isFollowing:) :
                          @selector(user:isNotFollowing:);
    [self invokeSelector:sel withTarget:delegate args:username, followee, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToQueryIfUser:isFollowing:error:);
    [self invokeSelector:sel withTarget:delegate args:username, followee, error,
        nil];
    return YES;
}

@end
