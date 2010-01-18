//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushNotificationSound : NSObject <NSCopying>
{
    NSString * name;
    NSString * file;
}

@property (nonatomic, copy, readonly) NSString * name;
@property (nonatomic, copy, readonly) NSString * file;


+ (id)soundWithName:(NSString *)aName file:(NSString *)aFile;
- (id)initWithName:(NSString *)aName file:(NSString *)aFile;

- (BOOL)isEqualToSound:(PushNotificationSound *)sound;

@end


@interface PushNotificationSound (ApplicationSoundHelpers)

+ (id)defaultSound;

+ (id)tritoneSound;
+ (id)bassoSound;
+ (id)blowSound;
+ (id)funkSound;
+ (id)glassSound;
+ (id)heroSound;
+ (id)pingSound;
+ (id)purrSound;
+ (id)sosumiSound;
+ (id)submarineSound;

+ (NSSet *)systemSounds;

@end
