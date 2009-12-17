//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BlockExistsResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "MGTwitterEngine.h"  // for [NSError twitterApiErrorDomain]
#import "TwitbitShared.h"

@interface BlockExistsResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation BlockExistsResponseProcessor

@synthesize username, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSDictionary * info = [statuses objectAtIndex:0];

    NSString * error = [info objectForKey:@"error"];
    SEL sel;
    if ([error isEqualToString:@"You are not blocking this user."])
        sel = @selector(userIsNotBlocked:);
    else
        sel = @selector(userIsBlocked:);

    if ([delegate respondsToSelector:sel])
        [delegate performSelector:sel withObject:username];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSString * twitterApiErrorDomain = [NSError twitterApiErrorDomain];
    if ([error.domain isEqual:twitterApiErrorDomain] && error.code == 404) {
        // Twitter sends a 404 when a block does not exist
        SEL sel = @selector(userIsNotBlocked:);
        if ([delegate respondsToSelector:sel])
            [delegate userIsNotBlocked:username];
    } else {
        // an actual error occurred
        SEL sel = @selector(failedToCheckIfUserIsBlocked:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToCheckIfUserIsBlocked:username error:error];
    }

    return YES;
}

@end
