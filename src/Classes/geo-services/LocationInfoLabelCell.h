//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationInfoLabelCell : UITableViewCell
{
    IBOutlet UILabel * streetLabel;
    IBOutlet UILabel * cityLabel;
    IBOutlet UILabel * countryLabel;
    IBOutlet UILabel * addressLabel;
    IBOutlet UIActivityIndicatorView * activityIndicator;
}

- (void)setStreet:(NSString *)street city:(NSString *)city
    country:(NSString *)country;

- (void)setLoading;
- (void)setFinishedLoading;

@end
