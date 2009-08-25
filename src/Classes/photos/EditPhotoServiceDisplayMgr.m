//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "EditPhotoServiceDisplayMgr.h"
#import "NSObject+RuntimeAdditions.h"

@implementation EditPhotoServiceDisplayMgr

@synthesize delegate;

+ (id)editServiceDisplayMgrWithServiceName:(NSString *)serviceName
{
    static NSDictionary * services = nil;
    if (!services) {
        services =
            [[NSDictionary alloc] initWithObjectsAndKeys:
            @"TwitPicEditPhotoServiceDisplayMgr", @"TwitPic",
            @"YfrogEditPhotoServiceDisplayMgr", @"Yfrog",
            @"TwitVidEditPhotoServiceDisplayMgr", @"TwitVid",
            @"FlickrEditPhotoServiceDisplayMgr", @"Flickr",
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

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
}

@end
