//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "LocationInfoViewController.h"
#import "RegexKitLite.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"
#import "CoordRecentHistoryCache.h"

enum {
    kLocationInfoSectionAddress,
    kLocationInfoSectionSearch,
    kLocationInfoSectionDirections
};

enum {
    kLocationInfoNearbyTweets,
    kLocationInfoSearchLocation
};

enum {
    kLocationInfoDirectionsTo,
    kLocationInfoDirectionsFrom
};


#define MAP_WIDTH 58
#define MAP_HEIGHT 58

@interface LocationInfoViewController ()

@property (nonatomic, readonly) LocationInfoLabelCell * addressCell;
@property (nonatomic, readonly) ButtonCell * directionsToCell;
@property (nonatomic, readonly) ButtonCell * directionsFromCell;
@property (nonatomic, readonly) UITableViewCell * searchLocationCell;
@property (nonatomic, readonly) UITableViewCell * nearbyTweetsCell;
@property (nonatomic, retain) TwitbitReverseGeocoder * reverseGeocoder;

@property (nonatomic, readonly) MKMapView * mapView;
@property (nonatomic, readonly) BasicMapAnnotation * mapAnnotation;

@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * country;

- (void)updateMapSpan;
- (void)updateMap;
- (void)showLocationInMaps:(NSString *)locationString;
- (void)showForwardOptions;
- (NSInteger)correctedSectionForSection:(NSInteger)section;
- (NSInteger)addressCellHeight;

- (void)layoutViews;

@end

@implementation LocationInfoViewController

@synthesize delegate;
@synthesize reverseGeocoder;
@synthesize street, city, country;

- (void)dealloc
{
    [headerView release];
    [headerBackgroundView release];
    [headerTopLine release];
    [headerViewPadding release];
    [titleLabel release];
    [mapThumbnail release];

    [addressCell release];
    [directionsToCell release];
    [directionsFromCell release];
    [searchLocationCell release];
    [nearbyTweetsCell release];

    [reverseGeocoder release];

    [mapView release];
    [mapAnnotation release];

    [street release];
    [city release];
    [country release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];

        headerBackgroundView.image =
            [UIImage imageNamed:@"UserHeaderDarkThemeGradient.png"];
        headerTopLine.backgroundColor = [UIColor blackColor];
        headerViewPadding.backgroundColor = [UIColor defaultDarkThemeCellColor];

        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.shadowColor = [UIColor blackColor];

        self.view.backgroundColor =
            [UIColor colorWithPatternImage:
            [UIImage imageNamed:@"DarkThemeBackground.png"]];
    }

    self.tableView.tableHeaderView = headerView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self layoutViews];
}

- (void)layoutViews
{
    CGRect titleLabelFrame = titleLabel.frame;
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    titleLabelFrame.size.width = landscape ? 369 : 209;
    titleLabel.frame = titleLabelFrame;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger correctedSection =
        [self correctedSectionForSection:indexPath.section];
    NSString * directionChar;
    switch (correctedSection) {
        case kLocationInfoSectionAddress:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case kLocationInfoSectionSearch:
            if (indexPath.row == kLocationInfoSearchLocation)
                [delegate showResultsForSearch:titleLabel.text];
            else {
                NSNumber * latitude =
                    [NSNumber
                    numberWithDouble:mapView.centerCoordinate.latitude];
                NSNumber * longitude =
                    [NSNumber
                    numberWithDouble:mapView.centerCoordinate.longitude];
                [delegate showResultsForNearbySearchWithLatitude:latitude
                    longitude:longitude];
            }
            break;
        case kLocationInfoSectionDirections:
            directionChar =
                indexPath.row == kLocationInfoDirectionsTo ? @"d" : @"s";

            NSString * locationWithoutCommas =
                [titleLabel.text stringByReplacingOccurrencesOfString:@"iPhone:"
                withString:@""];
            NSString * urlString =
                [[NSString
                stringWithFormat:@"http://maps.google.com/maps?%@addr=%@",
                directionChar, locationWithoutCommas]
                stringByAddingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding];
            NSURL * url = [NSURL URLWithString:urlString];
            [[UIApplication sharedApplication] openURL:url];
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger correctedSection =
        [self correctedSectionForSection:indexPath.section];
    return correctedSection == kLocationInfoSectionAddress ?
        [self addressCellHeight] : 44;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return foundAddress ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows;

    NSInteger correctedSection = [self correctedSectionForSection:section];
    switch (correctedSection) {
        case kLocationInfoSectionAddress:
            numRows = 1;
            break;
        case kLocationInfoSectionSearch:
            numRows = 2;
            break;
        case kLocationInfoSectionDirections:
            numRows = 2;
            break;
    }

    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    NSInteger correctedSection =
        [self correctedSectionForSection:indexPath.section];
    switch (correctedSection) {
        case kLocationInfoSectionAddress:
            cell = self.addressCell;
            break;
        case kLocationInfoSectionSearch:
            cell =
                indexPath.row == kLocationInfoNearbyTweets ?
                self.nearbyTweetsCell : self.searchLocationCell;
            break;
        case kLocationInfoSectionDirections:
            cell =
                indexPath.row == kLocationInfoDirectionsTo ?
                self.directionsToCell : self.directionsFromCell;
            break;
    }

    return cell;
}

#pragma mark TwitbitReverseGeocoderDelegate implementation

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
    didFindPlacemark:(MKPlacemark *)placemark
{
    foundAddress = YES;
    self.street =
        streetLevel && placemark.subThoroughfare && placemark.thoroughfare ?
        [NSString stringWithFormat:@"%@ %@",
        placemark.subThoroughfare, placemark.thoroughfare] :
        nil;
    NSString * administrativeArea =
        placemark.administrativeArea ? placemark.administrativeArea : @"";
    self.city =
        [NSString stringWithFormat:@"%@ %@", placemark.locality,
        administrativeArea];
    self.country = placemark.country;
    [self.addressCell setStreet:self.street city:self.city
        country:self.country];
    [self.addressCell setFinishedLoading];

    if (geocoder) { // not from the cache
        CoordRecentHistoryCache * coordCache =
            [CoordRecentHistoryCache instance];
        CLLocationCoordinate2D cacheCoord = self.reverseGeocoder.coordinate;
        CLLocation * cacheLocation =
            [[[CLLocation alloc]
            initWithLatitude:cacheCoord.latitude longitude:cacheCoord.longitude]
            autorelease];
        [coordCache setObject:placemark forKey:cacheLocation];
    }

    [self.tableView reloadData];
}

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
    didFailWithError:(NSError *)error
{
    foundAddress = NO;
    [self.tableView reloadData];
}

#pragma mark MKMapViewDelegate implementation

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    [self updateMap];
}

- (void)updateMap
{
    self.mapAnnotation.coordinate = self.mapView.centerCoordinate;
    
    UIGraphicsBeginImageContext(self.mapView.bounds.size);
    [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [mapThumbnail setImage:image];

    [self updateMapSpan];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        [self showLocationInMaps:titleLabel.text]; // hack

    [sheet autorelease];
}

#pragma mark LocationInfoViewController implementation

- (void)setLocationString:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    self.street = nil;
    self.city = nil;
    self.country = nil;

    foundAddress = YES;
    static NSString * coordRegex =
        @"[^[-\\d\\.]]*([-\\d\\.]+\\s*,\\s*[-\\d\\.]+)[^[-\\d\\.]]*";

    streetLevel = [locationString isMatchedByRegex:coordRegex];

    titleLabel.text = locationString;

    [self.addressCell setLoading];
    [self.reverseGeocoder cancel];
    self.reverseGeocoder =
        [[[TwitbitReverseGeocoder alloc] initWithCoordinate:coordinate] autorelease];
    self.reverseGeocoder.delegate = self;
    CoordRecentHistoryCache * coordCache = [CoordRecentHistoryCache instance];
    CLLocation * coordAsLocation =
        [[[CLLocation alloc]
        initWithLatitude:coordinate.latitude longitude:coordinate.longitude]
        autorelease];
    MKPlacemark * cachedPlacemark = [coordCache objectForKey:coordAsLocation];
    if (!cachedPlacemark)
        [self.reverseGeocoder start];
    else {
        NSLog(@"Using placemark from cache");
        [self reverseGeocoder:nil didFindPlacemark:cachedPlacemark];
    }

    // the multiple map updates seem excessive, but they consistently cause the
    // map to render, which doesn't happen if either is removed
    [self updateMap];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    self.mapAnnotation.coordinate = coordinate;
    [self updateMap];
}

- (LocationInfoLabelCell *)addressCell
{
    if (!addressCell) {
        NSArray * nib =
            [[NSBundle mainBundle]
            loadNibNamed:@"LocationInfoLabelCell" owner:self options:nil];

        addressCell = [[nib objectAtIndex:0] retain];

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            addressCell.backgroundColor = [UIColor defaultDarkThemeCellColor];
            [addressCell setKeyColor:[UIColor twitchBlueOnDarkBackgroundColor]];
            [addressCell setValueColor:[UIColor whiteColor]];
        }
    }

    return addressCell;
}

- (ButtonCell *)directionsToCell
{
    if (!directionsToCell) {
        NSArray * nib =
            [[NSBundle mainBundle]
            loadNibNamed:@"ButtonCellView" owner:self options:nil];

        directionsToCell = [[nib objectAtIndex:0] retain];

        [directionsToCell
            setText:NSLocalizedString(@"locationinfo.directionsto", @"")];

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            directionsToCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            [directionsToCell
                setButtonTextColor:[UIColor twitchBlueOnDarkBackgroundColor]];
        }
    }

    return directionsToCell;
}

- (ButtonCell *)directionsFromCell
{
    if (!directionsFromCell) {
        NSArray * nib =
            [[NSBundle mainBundle]
            loadNibNamed:@"ButtonCellView" owner:self options:nil];

        directionsFromCell = [[nib objectAtIndex:0] retain];

        [directionsFromCell
            setText:NSLocalizedString(@"locationinfo.directionsfrom", @"")];
        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            directionsFromCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            [directionsFromCell
                setButtonTextColor:[UIColor twitchBlueOnDarkBackgroundColor]];
        }
    }

    return directionsFromCell;
}

- (UITableViewCell *)searchLocationCell
{
    if (!searchLocationCell) {
        searchLocationCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        searchLocationCell.textLabel.text =
            NSLocalizedString(@"locationinfo.searchlocation", @"");
        searchLocationCell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;
        searchLocationCell.imageView.image =
            [UIImage imageNamed:@"MagnifyingGlass.png"];
        searchLocationCell.imageView.highlightedImage =
            [UIImage imageNamed:@"MagnifyingGlassHighlighted.png"];

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            searchLocationCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            searchLocationCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return searchLocationCell;
}

- (UITableViewCell *)nearbyTweetsCell
{
    if (!nearbyTweetsCell) {
        nearbyTweetsCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        nearbyTweetsCell.textLabel.text =
            NSLocalizedString(@"locationinfo.nearbytweets", @"");
        nearbyTweetsCell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;
        nearbyTweetsCell.imageView.image =
            [UIImage imageNamed:@"NearbyTweetsButtonIcon.png"];

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            nearbyTweetsCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            nearbyTweetsCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return nearbyTweetsCell;
}

- (void)updateMapSpan
{
    MKCoordinateRegion region = mapView.region;
    MKCoordinateSpan span;
    span.latitudeDelta = .001;
    region.span = span;
    self.mapView.region = region;
}

- (MKMapView *)mapView
{
    if (!mapView) {
        CGRect frame = CGRectMake(0, 0, MAP_WIDTH * 1.5, MAP_HEIGHT * 1.5);
        mapView = [[MKMapView alloc] initWithFrame:frame];
        mapView.delegate = self;
        [mapView addAnnotation:self.mapAnnotation];
    }

    return mapView;
}

- (BasicMapAnnotation *)mapAnnotation
{
    if (!mapAnnotation)
        mapAnnotation = [[BasicMapAnnotation alloc] init];

    return mapAnnotation;
}

- (void)showLocationInMaps:(NSString *)locationString
{
    NSString * locationWithoutCommas =
        [locationString stringByReplacingOccurrencesOfString:@"iPhone:"
        withString:@""];
    NSString * urlString =
        [[NSString
        stringWithFormat:@"http://maps.google.com/maps?q=%@",
        locationWithoutCommas]
        stringByAddingPercentEscapesUsingEncoding:
        NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)showForwardOptions
{
    NSString * cancel =
        NSLocalizedString(@"locationinfo.actions.cancel", @"");
    NSString * maps =
        NSLocalizedString(@"locationinfo.actions.maps", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self
        cancelButtonTitle:cancel destructiveButtonTitle:nil
        otherButtonTitles:maps, nil];

    // The alert sheet needs to be displayed in the UITabBarController's view.
    // If it's displayed in a child view, the action sheet will appear to be
    // modal on top of the tab bar, but it will not intercept any touches that
    // occur within the tab bar's bounds. Thus about 3/4 of the 'Cancel' button
    // becomes unusable. Reaching for the UITabBarController in this way is
    // definitely a hack, but fixes the problem for now.
    UIView * rootView =
        self.parentViewController.parentViewController.view;
    [sheet showInView:rootView];
}

- (NSInteger)correctedSectionForSection:(NSInteger)section
{
    return foundAddress ? section : section + 1;
}

- (NSInteger)addressCellHeight
{
    NSInteger height;
    if (!self.street && !self.city && !self.country) {
        height = 84;
    } else {
        height = 21;
        height = self.street ? height + 21 : height;
        height = self.city ? height + 21 : height;
        height = self.country ? height + 21 : height;
    }

    return height;
}

@end
