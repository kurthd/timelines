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
    return [self soundWithName:@"Default" file:@"default"];
}

+ (id)alarmSound
{
    return [self soundWithName:@"Alarm" file:@"Alarm.aiff"];
}

+ (id)chimeSound
{
    return [self soundWithName:@"Chime" file:@"Chime.aiff"];
}

+ (id)electronicSound
{
    return [self soundWithName:@"Electronic" file:@"Electronic.aiff"];
}

+ (id)synthesizerSound
{
    return [self soundWithName:@"Synthesizer" file:@"Synthesizer.aiff"];
}

+ (id)triangleSound
{
    return [self soundWithName:@"Triangle" file:@"Triangle.aiff"];
}

+ (NSSet *)systemSounds
{
    return [NSSet setWithObjects:[self tritoneSound],
                                 [self alarmSound],
                                 [self chimeSound],
                                 [self electronicSound],
                                 [self synthesizerSound],
                                 [self triangleSound],
                                 nil];
}

@end
