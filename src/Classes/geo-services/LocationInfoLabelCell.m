//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationInfoLabelCell.h"

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

    CGRect streetLabelFrame = streetLabel.frame;
    // streetLabel.frame = streetLabelFrame;

    CGRect cityLabelFrame = cityLabel.frame;
    cityLabelFrame.origin.y =
        streetLabelFrame.origin.y + (streetLabel.text ? 21 : 0);
    cityLabel.frame = cityLabelFrame;

    CGRect countryLabelFrame = countryLabel.frame;
    countryLabelFrame.origin.y =
        cityLabelFrame.origin.y + (cityLabel.text ? 21 : 0);
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
    
@end
