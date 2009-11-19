//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchListsResponseProcessor.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "UserTwitterList.h"
#import "UserTwitterList+CoreDataAdditions.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "TwitbitShared.h"

@interface FetchListsResponseProcessor ()
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * cursor;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@property (nonatomic, retain) NSManagedObjectContext * context;
@end

@implementation FetchListsResponseProcessor

@synthesize credentials, username, cursor, delegate, context;

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                      username:(NSString *)aUsername
                        cursor:(NSString *)aCursor
                       context:(NSManagedObjectContext *)aContext
                      delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id processor = [[[self class] alloc] initWithCredentials:someCredentials
                                                    username:aUsername
                                                      cursor:aCursor
                                                     context:aContext
                                                    delegate:aDelegate];
    return [processor autorelease];
}

- (void)dealloc
{
    self.credentials = nil;
    self.username = nil;
    self.cursor = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                 username:(NSString *)aUsername
                   cursor:(NSString *)aCursor
                  context:(NSManagedObjectContext *)aContext
                 delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.credentials = someCredentials;
        self.username = aUsername;
        self.cursor = aCursor;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)rawStatuses
{
    if (!rawStatuses)
        return NO;

    NSAssert1(rawStatuses.count == 1, @"Expected one list element, but got %d.",
        rawStatuses.count);

    NSDictionary * wrapper = [rawStatuses objectAtIndex:0];
    NSArray * listsData = [wrapper objectForKey:@"lists"];
    NSAssert1(listsData, @"No lists found in dictionary: %@", wrapper);

    NSMutableArray * lists = [NSMutableArray arrayWithCapacity:listsData.count];
    for (NSDictionary * listData in listsData) {
        NSDictionary * userData = [listData objectForKey:@"user"];
        NSNumber * userId = [userData objectForKey:@"id"];
        User * user = [User findOrCreateWithId:userId context:context];
        [self populateUser:user fromData:userData];

        NSNumber * listId = [listData objectForKey:@"id"];
        UserTwitterList * list = [UserTwitterList findOrCreateWithId:listId
                                                         credentials:credentials
                                                             context:context];
        [self populateList:list fromData:listData];

        list.user = user;
        list.credentials = credentials;

        [lists addObject:list];
    }

    NSError * error = nil;
    if (![context save:&error])
        NSLog(@"Failed to save state after downloading lists: %@",
            [error detailedDescription]);

    NSString * nextCursor = [[wrapper objectForKey:@"next_cursor"] description];
    if ([nextCursor isEqualToString:@"0"])
        nextCursor = nil;

    SEL sel = @selector(lists:fetchedForUser:fromCursor:nextCursor:);
    if ([delegate respondsToSelector:sel])
        [delegate lists:lists fetchedForUser:username
             fromCursor:cursor nextCursor:nextCursor];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to process lists: %@", [error detailedDescription]);

    SEL sel = @selector(failedToFetchListsForUser:fromCursor:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchListsForUser:username
                                 fromCursor:cursor
                                      error:error];

    return YES;
}

@end
