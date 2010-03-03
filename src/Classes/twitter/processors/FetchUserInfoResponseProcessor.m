//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchUserInfoResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "TwitbitShared.h"

@interface FetchUserInfoResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchUserInfoResponseProcessor

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

- (BOOL)processResponse:(NSArray *)infos
{
    if (!infos)
        return NO;

    NSAssert1(infos.count == 1, @"Expected 1 user info but received: %d.",
        infos.count);
    NSDictionary * info = [infos objectAtIndex:0];

    NSNumber * userId = [[info objectForKey:@"id"] twitterIdentifierValue];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:info context:context];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"username == %@", user.username];
    TwitterCredentials * ctls =
        [TwitterCredentials findFirst:predicate context:context];
    if (ctls)
        ctls.user = user;

    NSError * error = nil;
    if (![context save:&error])
        NSLog(@"Failed to save state: %@", [error detailedDescription]);

    SEL sel = @selector(userInfo:fetchedForUsername:);
    if ([delegate respondsToSelector:sel])
        [delegate userInfo:user fetchedForUsername:username];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchUserInfoForUsername:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchUserInfoForUsername:username error:error];

    return YES;
}

@end
