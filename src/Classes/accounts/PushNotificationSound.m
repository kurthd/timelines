//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "PushNotificationSound.h"

@interface PushNotificationSound ()

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * file;

@end

@implementation PushNotificationSound

@synthesize name, file;

+ (id)soundWithName:(NSString *)aName file:(NSString *)aFile
{
    return [[[self alloc] initWithName:aName file:aFile] autorelease];
}

- (void)dealloc
{
    self.name = nil;
    self.file = nil;

    [super dealloc];
}

- (id)initWithName:(NSString *)aName file:(NSString *)aFile
{
    if (self = [super init]) {
        self.name = aName;
        self.file = aFile;
    }

    return self;
}

- (NSString *)description
{
    return self.name;
}

- (BOOL)isEqualToSound:(PushNotificationSound *)sound
{
    return [self.name isEqualToString:sound.name] &&
           [self.file isEqualToString:sound.file];
}

#pragma mark NSCopying implementation

- (id)copyWithZone:(NSZone *)zone
{
    return [[PushNotificationSound alloc] initWithName:name file:file];
}

@end


@implementation PushNotificationSound (ApplicationSoundHelpers)

+ (id)defaultSound
{
    return [self tritoneSound];
}

+ (id)tritoneSound
{
    return [self soundWithName:@"Tri-tone" file:@"default"];
}

+ (id)bassoSound
{
    return [self soundWithName:@"Basso" file:@"Basso.caf"];
}

+ (id)blowSound
{
    return [self soundWithName:@"Blow" file:@"Blow.caf"];
}

+ (id)funkSound
{
    return [self soundWithName:@"Funk" file:@"Funk.caf"];
}

+ (id)glassSound
{
    return [self soundWithName:@"Glass" file:@"Glass.caf"];
}

+ (id)heroSound
{
    return [self soundWithName:@"Hero" file:@"Hero.caf"];
}

+ (id)pingSound
{
    return [self soundWithName:@"Ping" file:@"Ping.caf"];
}

+ (id)purrSound
{
    return [self soundWithName:@"Purr" file:@"Purr.caf"];
}

+ (id)sosumiSound
{
    return [self soundWithName:@"Sosumi" file:@"Sosumi.caf"];
}

+ (id)submarineSound
{
    return [self soundWithName:@"Submarine" file:@"Submarine.caf"];
}

+ (NSSet *)systemSounds
{
    return [NSSet setWithObjects:[self tritoneSound],
                                 [self bassoSound],
                                 [self blowSound],
                                 [self funkSound],
                                 [self glassSound],
                                 [self heroSound],
                                 [self pingSound],
                                 [self purrSound],
                                 [self sosumiSound],
                                 [self submarineSound],
                                 nil];
}

@end
