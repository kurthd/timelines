//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PhotoBrowser.h"
#import "UIWebView+FileLoadingAdditions.h"

@interface PhotoBrowser ()

- (void)showImage:(UIImage *)image;

@end

@implementation PhotoBrowser

- (void)dealloc
{
    [photoView release];
    [photoList release];
    [super dealloc];
}

- (IBAction)done:(id)sender
{
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addRemotePhoto:(RemotePhoto *)remotePhoto
{
    NSLog(@"Adding photo: %@", remotePhoto);
    NSLog(@"Photo list: %@", photoList);
    [self.photoList addObject:remotePhoto];
    NSLog(@"photo list count: %d", [self.photoList count]);
    [self setIndex:[self.photoList count] - 1];
}

- (void)setIndex:(NSUInteger)index
{
    NSLog(@"Setting photo index");
    RemotePhoto * selectedImage = [photoList objectAtIndex:index];
    NSLog(@"Index: %d", index);
    NSLog(@"Selected image: %@", selectedImage);
    if (selectedImage.image)
        [self showImage:selectedImage.image];
    // Update currently selected index member variable
    // if image is available
    //   set it on the web view
    // else
    //   fetch it
    //   ...when any image returns, set the image in the array
    //      and, if that image's index is selected
    //      set the web view
    // Update nav buttons
}

- (NSMutableArray *)photoList
{
    if (!photoList)
        photoList = [[NSMutableArray array] retain];

    return photoList;
}

- (void)showImage:(UIImage *)image
{
    
}

@end
