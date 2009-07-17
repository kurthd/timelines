//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PhotoBrowser.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface PhotoBrowser ()

- (void)showImage:(UIImage *)image;
- (void)showImageZoomed:(UIImage *)image;
- (RemotePhoto *)remoteImageForUrl:(NSString *)url;
- (void)changeZoom;
- (void)processPotentialSingleTap;
- (void)processSingleTap;
- (void)processDoubleTap;
- (void)startFadeTimer;
- (void)fadeBars;
- (void)showBars;
- (void)processFadeBarsEvent;
- (void)setLoadingState:(BOOL)loading;
- (void)hideStatusBar;

- (void)sendSelectedImageInEmail;
- (void)saveSelectedImageToAlbum;

- (void)displayComposerMailSheet;

@end

@implementation PhotoBrowser

- (void)dealloc
{
    [photoView release];
    [photoList release];
    [navItem release];
    [actionButton release];
    [forwardButton release];
    [backButton release];
    [loadingView release];
    [navigationBar release];
    [toolbar release];
    [super dealloc];
}

- (void)viewDidLoad
{
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y = -20;
    viewFrame.size.height = 480;
    self.view.frame = viewFrame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startFadeTimer];
    navigationBar.alpha = 1;
    toolbar.alpha = 1;
    barsFaded = NO;
    isDisplayed = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    isDisplayed = NO;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatarImage = [UIImage imageWithData:data];

    RemotePhoto * remoteImage = [self remoteImageForUrl:[url absoluteString]];
    remoteImage.image = avatarImage;

    RemotePhoto * selectedImage = [self.photoList objectAtIndex:selectedIndex];
    if ([remoteImage isEqual:selectedImage])
        [self showImage:avatarImage];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UIResponder implementation

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self startFadeTimer];

    UITouch * touch = [touches anyObject];
    NSUInteger tapCount = [touch tapCount];

    switch (tapCount) {
        case 1:
            [self performSelector:@selector(processPotentialSingleTap)
                withObject:nil afterDelay:0.3];
            break;
        case 2:
            [self processDoubleTap];
            break;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    notSingleTap = YES;
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"User clicked button at index: %d.", buttonIndex);

    switch (buttonIndex) {
        case 0:
            [self sendSelectedImageInEmail];
            break;
        case 1:
            [self saveSelectedImageToAlbum];
            break;
    }

    [sheet autorelease];
}

#pragma mark MFMailComposeViewControllerDelegate implementation

- (void)mailComposeController:(MFMailComposeViewController *)controller
    didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    if (result == MFMailComposeResultFailed) {
        NSString * title =
            NSLocalizedString(@"photobrowser.emailerror.title", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:[error description]];
        [alert show];
    }
    
    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

#pragma mark PhotoBrowser implementation

- (IBAction)done:(id)sender
{
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addRemotePhoto:(RemotePhoto *)remotePhoto
{
    NSLog(@"Adding photo: %@", remotePhoto);
    if ([self.photoList containsObject:remotePhoto])
        [self setIndex:[self.photoList indexOfObject:remotePhoto]];
    else {
        // Add photo after currently selected index and remove everything after
        NSInteger countMinusOne = [self.photoList count] - 1;
        if (selectedIndex < countMinusOne) {
            NSRange afterSelectedRange =
                NSMakeRange(selectedIndex + 1, countMinusOne - selectedIndex);
            [self.photoList removeObjectsInRange:afterSelectedRange];
        }
        [self.photoList addObject:remotePhoto];
        [self setIndex:[self.photoList count] - 1];
    }
}

- (void)setIndex:(NSUInteger)index
{
    NSLog(@"Setting photo index: %d", index);
    RemotePhoto * selectedImage = [photoList objectAtIndex:index];
    NSLog(@"Selected image: %@", selectedImage);

    selectedIndex = index;

    if (selectedImage.image)
        [self showImage:selectedImage.image];
    else {
        NSURL * avatarUrl = [NSURL URLWithString:selectedImage.url];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
        [self setLoadingState:YES];
    }

    navItem.title =
        selectedImage.name ? selectedImage.name : selectedImage.url;

    backButton.enabled = index > 0;
    forwardButton.enabled = index < [photoList count] - 1;
}

- (NSMutableArray *)photoList
{
    if (!photoList)
        photoList = [[NSMutableArray array] retain];

    return photoList;
}

- (void)showImage:(UIImage *)image
{
    static const NSInteger MAX_HEIGHT = 480;
    static const NSInteger MAX_WIDTH = 320;
    
    CGSize imageSize = image.size;
    if (imageSize.height > MAX_HEIGHT || imageSize.width > MAX_WIDTH) {
        CGFloat heightToWidthRatio =
            (CGFloat)imageSize.height / imageSize.width;
        if (heightToWidthRatio > (CGFloat)MAX_HEIGHT / MAX_WIDTH) {
            imageSize.height = MAX_HEIGHT;
            imageSize.width = 1 / heightToWidthRatio * MAX_HEIGHT;
        } else {
            imageSize.height = heightToWidthRatio * MAX_WIDTH;
            imageSize.width = MAX_WIDTH;
        }
    }

    CGRect photoViewFrame = photoView.frame;
    photoViewFrame.size = imageSize;
    photoViewFrame.origin.x = (MAX_WIDTH - imageSize.width) / 2;
    photoViewFrame.origin.y = (MAX_HEIGHT - imageSize.height) / 2 - 20;
    photoView.frame = photoViewFrame;

    photoView.image = image;

    [self setLoadingState:NO];
}

- (void)showImageZoomed:(UIImage *)image
{
    CGRect photoViewFrame = photoView.frame;
    photoViewFrame.size.height = 480;
    photoViewFrame.size.width = 320;
    photoViewFrame.origin.x = 0;
    photoViewFrame.origin.y = -20;
    photoView.frame = photoViewFrame;

    photoView.image = image;
}

- (void)goBack:(id)sender
{
    [self startFadeTimer];
    [self setIndex:selectedIndex - 1];
}

- (void)goForward:(id)sender
{
    [self startFadeTimer];
    [self setIndex:selectedIndex + 1];
}

- (RemotePhoto *)remoteImageForUrl:(NSString *)url
{
    RemotePhoto * returnVal = nil;
    for (RemotePhoto * remoteImage in self.photoList) {
        if ([remoteImage.url isEqual:url]) {
            returnVal = remoteImage;
            break;
        }
    }

    return returnVal;
}

- (void)changeZoom
{
    RemotePhoto * selectedPhoto = [self.photoList objectAtIndex:selectedIndex];
    UIImage * image = selectedPhoto.image;
    if (image) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
            forView:photoView cache:YES];

        if (zoomed)
            [self showImage:image];
        else
            [self showImageZoomed:image];

        [UIView commitAnimations];

        zoomed = !zoomed;
    }
}

- (void)processPotentialSingleTap
{
    if (!notSingleTap) {
        [self processSingleTap];
    }
    notSingleTap = NO;
}

- (void)processSingleTap
{
    if (barsFaded)
        [self showBars];
    else
        [self fadeBars];
}

- (void)processDoubleTap
{
    notSingleTap = YES;
    [self changeZoom];
}

- (void)startFadeTimer
{
    touchesCount++;
    [self performSelector:@selector(processFadeBarsEvent) withObject:nil
        afterDelay:5];
}

- (void)fadeBars
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:navigationBar cache:YES];

    navigationBar.alpha = 0;
    
    [UIView commitAnimations];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:toolbar cache:YES];

    toolbar.alpha = 0;
    
    [UIView commitAnimations];

    [self performSelector:@selector(hideStatusBar) withObject:nil
        afterDelay:0.6];

    barsFaded = YES;
}

- (void)hideStatusBar
{
    if (isDisplayed && barsFaded)
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
}

- (void)showBars
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:navigationBar cache:YES];

    navigationBar.alpha = 1;

    [UIView commitAnimations];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:toolbar cache:YES];

    toolbar.alpha = 1;

    [UIView commitAnimations];

    if (isDisplayed)
        [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];

    barsFaded = NO;
}

- (void)processFadeBarsEvent
{
    touchesCount--;
    if (touchesCount == 0)
        [self fadeBars];
}

- (IBAction)showActions:(id)sender
{
    [self startFadeTimer];

    NSString * cancel = NSLocalizedString(@"photobrowser.actions.cancel", @"");
    NSString * email = NSLocalizedString(@"photobrowser.actions.email", @"");
    NSString * save = NSLocalizedString(@"photobrowser.actions.save", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self cancelButtonTitle:cancel
        destructiveButtonTitle:nil otherButtonTitles:email, save, nil];

    [sheet showInView:self.view];
}

- (void)sendSelectedImageInEmail
{
    NSLog(@"Sending image in email...");
    if ([MFMailComposeViewController canSendMail]) {
        [self displayComposerMailSheet];
    } else {
        NSString * title =
            NSLocalizedString(@"photobrowser.unabletosendmail.title", @"");
        NSString * message =
            NSLocalizedString(@"photobrowser.unabletosendmail.message", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alert show];
    }
}

- (void)displayComposerMailSheet
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];

    RemotePhoto * selectedPhoto = [self.photoList objectAtIndex:selectedIndex];
    UIImage * image = selectedPhoto.image;
    if (image) {
    	MFMailComposeViewController * picker =
    	    [[MFMailComposeViewController alloc] init];
    	picker.mailComposeDelegate = self;

        NSData * imageData = UIImagePNGRepresentation(image);
        [picker addAttachmentData:imageData mimeType:@"image/png"
            fileName:@"image"];

    	[self presentModalViewController:picker animated:YES];

        [picker release];
    }
}

- (void)saveSelectedImageToAlbum
{
    NSLog(@"Saving image to album...");
    RemotePhoto * selectedPhoto = [self.photoList objectAtIndex:selectedIndex];
    UIImage * image = selectedPhoto.image;
    if (image)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}

- (void)setLoadingState:(BOOL)loading
{
    actionButton.enabled = !loading;
    loadingView.hidden = !loading;
}

@end
