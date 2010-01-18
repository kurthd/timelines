//
//  Copyright  High Order Bit, Inc.2010. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundPlayer : NSObject
{
}

/**
 * fileName must be the full path to the file.
 */
- (BOOL)playSound:(NSString *)fileName;

@end


@interface SoundPlayer (BundleHelpers)

- (BOOL)playSoundInMainBundle:(NSString *)fileName;
- (BOOL)playSound:(NSString *)fileName inBundle:(NSBundle *)bundle;

@end

