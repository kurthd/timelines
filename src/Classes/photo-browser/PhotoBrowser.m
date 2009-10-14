//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PhotoBrowser.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CommonTwitterServicePhotoSource.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "SettingsReader.h"

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
- (void)showStatusBar;

- (void)sendSelectedImageInEmail;
- (void)saveSelectedImageToAlbum;
- (void)openImageInBrowser;

- (void)displayComposerMailSheet;

- (void)configureViewForInterfaceOrientation:
    (UIInterfaceOrientation)orientation;

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
    [loadingIndicator release];
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

    previousOrientation = -1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startFadeTimer];
    navigationBar.alpha = 1;
    toolbar.alpha = 1;
    barsFaded = NO;
    isDisplayed = YES;

    // Calling this here fixes a bug where rotating the interface to
    // landscape, closing the photo browser (which forces the orientation back
    // to portrait), and then opening a picture while still in portrait
    // orientation has the view elements still laid out as if they're in
    // landscape mode. This is because the various rotation methods are called
    // before isDisplayed is set to YES (e.g. this method is called), but
    // isDisplayed seems to fix a UI bug of its own.
    [self configureViewForInterfaceOrientation:self.interfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    if (isDisplayed)
        [self configureViewForInterfaceOrientation:orientation];

    previousOrientation = orientation;

    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
    duration:(NSTimeInterval)duration
{
    if (![[UIApplication sharedApplication] isStatusBarHidden]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
        [self performSelector:@selector(showStatusBar) withObject:nil
            afterDelay:0.3];
    }

    RemotePhoto * selectedImage = [self.photoList objectAtIndex:selectedIndex];
    UIImage * image = selectedImage.image;
    [self showImageZoomed:image];
}

#pragma mark PhotoSourceDelegate implementation

- (void)fetchedImage:(UIImage *)image withUrl:(NSString *)url
{
    NSLog(@"Received image for url: %@", url);
    RemotePhoto * remoteImage = [self remoteImageForUrl:url];
    remoteImage.image = image;

    RemotePhoto * selectedImage = [self.photoList objectAtIndex:selectedIndex];
    if ([remoteImage isEqual:selectedImage])
        [self showImage:image];
}

- (void)failedToFetchImageWithUrl:(NSString *)url error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"photobrowser.fetcherror.title", @"");
    NSString * message = error.localizedDescription;
    NSString * cancelTitle = NSLocalizedString(@"alert.dismiss", @"");

    UIAlertView * alert =
        [[[UIAlertView alloc] initWithTitle:title message:message
        delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil]
        autorelease];

    [alert show];
}

- (void)unableToFindImageForUrl:(NSString *)url
{
    [self performSelector:@selector(openImageInBrowser) withObject:nil
        afterDelay:0.7];
}

#pragma mark UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // only one button
    [self done:self];
}

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
        case 2:
            [self openImageInBrowser];
            break;
    }

    [sheet autorelease];
}

#pragma mark MFMailComposeViewControllerDelegate implementation

- (void)mailComposeController:(MFMailComposeViewController *)controller
    didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    sendingInEmail = NO;
    if (result == MFMailComposeResultFailed) {
        NSString * title =
            NSLocalizedString(@"photobrowser.emailerror.title", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:[error description]];
        [alert show];
    }

    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

    RemotePhoto * selectedPhoto = [self.photoList objectAtIndex:selectedIndex];
    UIImage * image = selectedPhoto.image;
    [self showImageZoomed:image];
}

#pragma mark PhotoBrowser implementation

- (IBAction)done:(id)sender
{
    isDisplayed = NO;
    UIStatusBarStyle statusBarStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIStatusBarStyleBlackOpaque : UIStatusBarStyleDefault;
    [[UIApplication sharedApplication]
        setStatusBarStyle:statusBarStyle animated:YES];
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
        [self.photoSource fetchImageWithUrl:selectedImage.url];
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
    NSLog(@"Photo Browser: showing image in original size");

    NSInteger maxHeight =
        (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ?
        480 : 320;
    NSInteger maxWidth =
        (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ?
        320 : 480;
    
    CGSize imageSize = image.size;
    if (imageSize.height > maxHeight || imageSize.width > maxWidth) {
        CGFloat heightToWidthRatio =
            (CGFloat)imageSize.height / imageSize.width;
        if (heightToWidthRatio > (CGFloat)maxHeight / maxWidth) {
            imageSize.height = maxHeight;
            imageSize.width = 1 / heightToWidthRatio * maxHeight;
        } else {
            imageSize.height = heightToWidthRatio * maxWidth;
            imageSize.width = maxWidth;
        }
    }

    CGRect photoViewFrame = photoView.frame;
    photoViewFrame.size = imageSize;
    photoViewFrame.origin.x = (maxWidth - imageSize.width) / 2;
    photoViewFrame.origin.y = (maxHeight - imageSize.height) / 2;
    photoView.frame = photoViewFrame;

    photoView.image = image;

    [self setLoadingState:NO];
}

- (void)showImageZoomed:(UIImage *)image
{
    NSLog(@"Photo Browser: showing zoomed image");
        
    CGRect photoViewFrame = photoView.frame;
    photoViewFrame.size.height =
        (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ?
        480 : 320;
    photoViewFrame.size.width =
        (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ?
        320 : 480;
    photoViewFrame.origin.x = 0;
    photoViewFrame.origin.y = 0;
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
    NSLog(@"Photo Browser: changing zoom");
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
    if (isDisplayed && barsFaded && !sendingInEmail)
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
}

- (void)showStatusBar
{
    if (!barsFaded)
        [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
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
    NSString * browser = NSLocalizedString(@"photobrowser.actions.browser", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self cancelButtonTitle:cancel
        destructiveButtonTitle:nil otherButtonTitles:email, save, browser, nil];

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
    sendingInEmail = YES;

    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
        animated:YES];

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

- (void)openImageInBrowser
{
    [self done:nil];
    RemotePhoto * selectedPhoto = [self.photoList objectAtIndex:selectedIndex];
    NSString * selectedUrl = selectedPhoto.url;
    [[TwitchWebBrowserDisplayMgr instance]
        performSelector:@selector(visitWebpage:) withObject:selectedUrl
        afterDelay:0.7];
}

- (void)setLoadingState:(BOOL)loading
{
    actionButton.enabled = !loading;
    loadingView.hidden = !loading;
}

- (NSObject<PhotoSource> *)photoSource
{
    if (!photoSource) {
        photoSource = [[CommonTwitterServicePhotoSource alloc] init];
        ((CommonTwitterServicePhotoSource *)photoSource).delegate = self;
    }

    return photoSource;
}

- (void)configureViewForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown) {

        CGRect navigationBarFrame = navigationBar.frame;
        navigationBarFrame.size.width = 320;
        navigationBar.frame = navigationBarFrame;

        CGRect photoViewFrame = photoView.frame;
        photoViewFrame.size.width = 320;
        photoViewFrame.size.height = 480;
        photoView.frame = photoViewFrame;

        CGRect toolbarFrame = toolbar.frame;
        toolbarFrame.size.width = 320;
        toolbarFrame.origin.y = 436;
        toolbar.frame = toolbarFrame;

        CGRect loadingViewFrame = loadingView.frame;
        loadingViewFrame.size.width = 320;
        loadingViewFrame.size.height = 480;
        loadingView.frame = loadingViewFrame;

        CGRect loadingIndicatorFrame = loadingIndicator.frame;
        loadingIndicatorFrame.origin.x = 141;
        loadingIndicatorFrame.origin.y = 221;
        loadingIndicator.frame = loadingIndicatorFrame;
    } else {
        CGRect navigationBarFrame = navigationBar.frame;
        navigationBarFrame.size.width = 480;
        navigationBar.frame = navigationBarFrame;

        CGRect photoViewFrame = photoView.frame;
        photoViewFrame.size.width = 480;
        photoViewFrame.size.height = 320;
        photoView.frame = photoViewFrame;

        CGRect toolbarFrame = toolbar.frame;
        toolbarFrame.size.width = 480;
        toolbarFrame.origin.y = 276;
        toolbar.frame = toolbarFrame;

        CGRect loadingViewFrame = loadingView.frame;
        loadingViewFrame.size.width = 480;
        loadingViewFrame.size.height = 320;
        loadingView.frame = loadingViewFrame;

        CGRect loadingIndicatorFrame = loadingIndicator.frame;
        loadingIndicatorFrame.origin.x = 221;
        loadingIndicatorFrame.origin.y = 141;
        loadingIndicator.frame = loadingIndicatorFrame;
    }
}

@end
