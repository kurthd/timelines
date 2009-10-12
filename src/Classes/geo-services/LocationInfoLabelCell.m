//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationInfoLabelCell.h"
#import "RotatableTabBarController.h"

@interface LocationInfoLabelCell ()

- (NSInteger)cellHeight;
- (NSInteger)cellWidth;

@end

@implementation LocationInfoLabelCell

- (void)dealloc
{
    [streetLabel release];
    [cityLabel release];
    [countryLabel release];
    [addressLabel release];
    [activityIndicator release];
    [super dealloc];
}

- (void)setStreet:(NSString *)street city:(NSString *)city
    country:(NSString *)country
{
    streetLabel.text = street;
    cityLabel.text = city;
    countryLabel.text = country;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect activityIndicatorFrame = activityIndicator.frame;
    activityIndicatorFrame.origin.y = ([self cellHeight] - 20) / 2;
    activityIndicatorFrame.origin.x = ([self cellWidth] - 20) / 2;
    activityIndicator.frame = activityIndicatorFrame;

    CGRect streetLabelFrame = streetLabel.frame;
    streetLabelFrame.size.width = [self cellWidth] - 87;
    streetLabel.frame = streetLabelFrame;

    CGRect cityLabelFrame = cityLabel.frame;
    cityLabelFrame.origin.y =
        streetLabelFrame.origin.y + (streetLabel.text ? 21 : 0);
    cityLabelFrame.size.width = [self cellWidth] - 87;
    cityLabel.frame = cityLabelFrame;

    CGRect countryLabelFrame = countryLabel.frame;
    countryLabelFrame.origin.y =
        cityLabelFrame.origin.y + (cityLabel.text ? 21 : 0);
    countryLabelFrame.size.width = [self cellWidth] - 87;
    countryLabel.frame = countryLabelFrame;
}

- (void)setLoading
{
    [activityIndicator startAnimating];
    streetLabel.hidden = YES;
    cityLabel.hidden = YES;
    countryLabel.hidden = YES;
    addressLabel.hidden = YES;
}

- (void)setFinishedLoading
{
    [activityIndicator stopAnimating];
    streetLabel.hidden = NO;
    cityLabel.hidden = NO;
    countryLabel.hidden = NO;
    addressLabel.hidden = NO;
}

- (NSInteger)cellHeight
{
    NSInteger height;
    if (!streetLabel.text && !cityLabel.text && !countryLabel.text)
        height = 84;
    else {
        height = 21;
        height = streetLabel.text ? height + 21 : height;
        height = cityLabel.text ? height + 21 : height;
        height = countryLabel.text ? height + 21 : height;
    }

    return height;
}

- (NSInteger)cellWidth
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];

    return landscape ? 458 : 298;
}

@end
