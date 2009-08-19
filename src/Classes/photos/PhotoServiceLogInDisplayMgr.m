//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServiceLogInDisplayMgr.h"
#import "NSObject+RuntimeAdditions.h"

@implementation PhotoServiceLogInDisplayMgr

@synthesize delegate;

+ (id)serviceWithServiceName:(NSString *)serviceName
{
    static NSDictionary * services = nil;
    if (!services) {
        services =
            [[NSDictionary alloc] initWithObjectsAndKeys:
            @"TwitPicLogInDisplayMgr", @"TwitPic",
            nil];
    }

    NSString * className = [services objectForKey:serviceName];
    NSAssert1(className, @"Failed to lookup class name for service: '%@'.",
        serviceName);
    Class class = [[self class] classNamed:className];

    return [[[class alloc] init] autorelease];
}

- (void)dealloc
{
    self.delegate = nil;
    [super dealloc];
}

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
}

@end
