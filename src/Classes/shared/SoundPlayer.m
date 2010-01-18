//
//  Copyright  High Order Bit, Inc.2010. All rights reserved.
//

#import "SoundPlayer.h"
#include <AudioToolbox/AudioToolbox.h>
#include <CoreFoundation/CoreFoundation.h>

static void soundCompletionCallback(SystemSoundID soundId, void * soundUrl)
{
    AudioServicesDisposeSystemSoundID(soundId);
    CFRelease(soundUrl);
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@implementation SoundPlayer

- (BOOL)playSound:(NSString *)fileName
{
    SystemSoundID    soundId;
    CFURLRef         soundUrl;

    soundUrl = CFURLCreateWithFileSystemPath(
        kCFAllocatorDefault,
        (CFStringRef) fileName,
        kCFURLPOSIXPathStyle,
        FALSE
    );

    // create a system sound ID to represent the sound file
    AudioServicesCreateSystemSoundID(soundUrl, &soundId);

    // Register the sound completion callback.
    // Again, useful when you need to free memory after playing.
    AudioServicesAddSystemSoundCompletion(
        soundId,
        NULL,
        NULL,
        soundCompletionCallback,
        (void *) soundUrl
    );

    // Play the sound file.
    AudioServicesPlaySystemSound(soundId);

    // Invoke a run loop on the current thread to keep the application
    // running long enough for the sound to play; the sound completion
    // callback later stops this run loop.
    CFRunLoopRun();

    return YES;
}

@end


@implementation SoundPlayer (BundleHelpers)

- (BOOL)playSoundInMainBundle:(NSString *)fileName
{
    return [self playSound:fileName inBundle:[NSBundle mainBundle]];
}

- (BOOL)playSound:(NSString *)fileName inBundle:(NSBundle *)bundle
{
    NSString * name = [fileName stringByDeletingPathExtension];
    NSString * extension = [fileName pathExtension];

    NSString * fullPath = [bundle pathForResource:name ofType:extension];

    return fullPath ? [self playSound:fullPath] : NO;
}

@end
