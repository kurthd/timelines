//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServiceLogInDisplayMgr.h"
#import "NSObject+RuntimeAdditions.h"

@interface PhotoServiceLogInDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation PhotoServiceLogInDisplayMgr

@synthesize delegate;
@synthesize rootViewController, credentials, context;

+ (id)logInDisplayMgrWithServiceName:(NSString *)serviceName
{
    static NSDictionary * services = nil;
    if (!services) {
        services =
            [[NSDictionary alloc] initWithObjectsAndKeys:
            @"TwitPicLogInDisplayMgr", @"TwitPic",
            @"YfrogLogInDisplayMgr", @"Yfrog",
            @"TwitVidLogInDisplayMgr", @"TwitVid",
            @"FlickrLogInDisplayMgr", @"Flickr",
            @"FlickrLogInDisplayMgr", @"Picasa",
            @"FlickrLogInDisplayMgr", @"Posterous",
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

    self.rootViewController = nil;
    self.credentials = nil;
    self.context = nil;

    [super dealloc];
}

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext
{
    self.rootViewController = aController;
    self.credentials = someCredentials;
    self.context = aContext;
}

@end
