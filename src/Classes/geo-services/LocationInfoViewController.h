//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationInfoLabelCell.h"
#import "ButtonCell.h"
#import "RoundedImage.h"
#import "LocationInfoViewControllerDelegate.h"
#import "TwitbitReverseGeocoder.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "AsynchronousNetworkFetcher.h"

@interface LocationInfoViewController :
    UITableViewController
    <UITableViewDelegate, UITableViewDataSource, TwitbitReverseGeocoderDelegate,
    UIActionSheetDelegate, AsynchronousNetworkFetcherDelegate>
{
    id<LocationInfoViewControllerDelegate> delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UILabel * titleLabel;
    IBOutlet RoundedImage * mapThumbnail;

    LocationInfoLabelCell * addressCell;
    ButtonCell * directionsToCell;
    ButtonCell * directionsFromCell;
    UITableViewCell * searchLocationCell;
    UITableViewCell * nearbyTweetsCell;

    TwitbitReverseGeocoder * reverseGeocoder;

    BOOL foundAddress;
    BOOL streetLevel;
    NSString * street;
    NSString * city;
    NSString * country;
    
    CLLocationCoordinate2D coord;
    
    AsynchronousNetworkFetcher * imageUrlFetcher;
}

@property (nonatomic, assign) id<LocationInfoViewControllerDelegate> delegate;

- (void)setLocationString:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate;

@end
