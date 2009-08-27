//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrEditPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"

@interface FlickrEditPhotoServiceDisplayMgr ()

@property (nonatomic, retain) FlickrCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) FlickrSettingsViewController *
    settingsViewController;

@property (nonatomic, retain) NetworkAwareViewController *
    tagsNetViewController;
@property (nonatomic, retain) FlickrTagsViewController * tagsViewController;

@property (nonatomic, retain) EditTextViewController * editTextViewController;

@property (nonatomic, retain) NSArray * tags;

@property (nonatomic, retain) FlickrDataFetcher * flickrDataFetcher;

@end

@implementation FlickrEditPhotoServiceDisplayMgr

@synthesize credentials, context;
@synthesize navigationController, settingsViewController;
@synthesize tagsNetViewController, tagsViewController;
@synthesize editTextViewController;
@synthesize tags;
@synthesize flickrDataFetcher;

- (void)dealloc
{
    self.credentials = nil;
    self.context = nil;

    self.navigationController = nil;
    self.settingsViewController = nil;

    self.tagsNetViewController = nil;
    self.tagsViewController = nil;

    self.editTextViewController = nil;

    self.tags = nil;

    self.flickrDataFetcher = nil;

    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

#pragma mark Public implementation

- (void)editServiceWithCredentials:(FlickrCredentials *)someCredentials
              navigationController:(UINavigationController *)aController
                           context:(NSManagedObjectContext *)aContext
{
    NSAssert1([someCredentials isKindOfClass:[FlickrCredentials class]],
        @"Expected flickr credentials, but got: %@", [someCredentials class]);

    self.credentials = someCredentials;
    self.context = aContext;
    self.navigationController = aController;

    self.settingsViewController.credentials = self.credentials;
    [self.navigationController pushViewController:self.settingsViewController
                                         animated:YES];
}

#pragma mark FlickrSettingsViewControllerDelegate implementation

- (void)deleteServiceWithCredentials:(FlickrCredentials *)toDelete
{
    [self.navigationController popViewControllerAnimated:YES];
    self.settingsViewController = nil;

    [self.delegate userWillDeleteAccountWithCredentials:toDelete];
    [toDelete.credentials removePhotoServiceCredentialsObject:toDelete];
    [self.context deleteObject:toDelete];
    [self.delegate userDidDeleteAccount];
}

- (void)userWantsToSelectTags:(FlickrCredentials *)someCredentials
{
    [self.navigationController
        pushViewController:self.tagsNetViewController animated:YES];

    self.tagsViewController.tags = self.tags;
    if (self.tags) {
        [self.tagsNetViewController setUpdatingState:kConnectedAndNotUpdating];
        [self.tagsNetViewController setCachedDataAvailable:YES];
    } else {
        [self.tagsNetViewController setUpdatingState:kConnectedAndUpdating];
        [self.tagsNetViewController setCachedDataAvailable:NO];

        self.flickrDataFetcher.token = someCredentials.token;
        [self.flickrDataFetcher fetchTags:someCredentials.userId];
    }
}

#pragma mark EditTextViewControllerDelegate implementation

- (void)userDidSetText:(NSString *)newTag
{
    if (newTag.length)
        [self.tagsViewController addSelectedTag:newTag];
}

#pragma mark FlickrDataFetcherDelegate implementation

- (void)dataFetcher:(FlickrDataFetcher *)fetcher
        fetchedTags:(NSDictionary *)someTags
{
    NSLog(@"Fetched tags: %@", someTags);

    NSMutableArray * newTags = [NSMutableArray array];
    NSArray * downloadedTags =
        [[[someTags objectForKey:@"who"]
                    objectForKey:@"tags"]
                    objectForKey:@"tag"];

    for (NSDictionary * data in downloadedTags)
        [newTags addObject:[data objectForKey:@"_text"]];
    self.tags = newTags;

    self.tagsViewController.tags = self.tags;
    [self.tagsNetViewController setUpdatingState:kConnectedAndNotUpdating];
    [self.tagsNetViewController setCachedDataAvailable:YES];
}

- (void)dataFetcher:(FlickrDataFetcher *)fetcher
  failedToFetchTags:(NSError *)error
{
    NSLog(@"Failed to fetch tags: %@", error);
}

#pragma mark FlickrTagsViewControllerDelegate implementation

- (void)userWantsToAddTag
{
    [self.navigationController pushViewController:self.editTextViewController
                                         animated:YES];
    self.editTextViewController.textField.text = @"";
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Network aware view will appear.");
}

#pragma mark Accessors

- (FlickrSettingsViewController *)settingsViewController
{
    if (!settingsViewController)
        settingsViewController =
            [[FlickrSettingsViewController alloc] initWithDelegate:self];

    return settingsViewController;
}

- (NetworkAwareViewController *)tagsNetViewController
{
    if (!tagsNetViewController) {
        tagsNetViewController =
            [[NetworkAwareViewController alloc]
            initWithTargetViewController:self.tagsViewController];
        tagsNetViewController.delegate = self;
        tagsNetViewController.navigationItem.title =
            NSLocalizedString(@"flickrtagsview.title", @"");
    }

    return tagsNetViewController;
}

- (FlickrTagsViewController *)tagsViewController
{
    if (!tagsViewController)
        tagsViewController =
            [[FlickrTagsViewController alloc] initWithDelegate:self];

    return tagsViewController;
}

- (FlickrDataFetcher *)flickrDataFetcher
{
    if (!flickrDataFetcher)
        flickrDataFetcher = [[FlickrDataFetcher alloc] initWithDelegate:self];

    return flickrDataFetcher;
}

- (EditTextViewController *)editTextViewController
{
    if (!editTextViewController) {
        editTextViewController =
            [[EditTextViewController alloc] initWithDelegate:self];
        editTextViewController.viewTitle =
            NSLocalizedString(@"addflickrtagview.title", @"");
    }

    return editTextViewController;
}

@end
