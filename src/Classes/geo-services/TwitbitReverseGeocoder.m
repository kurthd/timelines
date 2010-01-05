//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import "TwitbitReverseGeocoder.h"
#import "AsynchronousNetworkFetcher.h"
#import "InfoPlistConfigReader.h"
#import "RegexKitLite.h"
#import "JSON.h"

@interface TwitbitReverseGeocoder ()

- (NSURL *)request;
+ (NSDictionary *)stateAbbreviationMapping;

@end

@implementation TwitbitReverseGeocoder

static NSMutableDictionary * stateAbbreviationMapping;

@synthesize delegate, querying, coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)query
{
    if (self = [super init])
        coordinate = query;

    return self;
}

- (void)start
{
    NSLog(@"Sending reverse geocode request: %f, %f", coordinate.latitude,
        coordinate.longitude);
    [AsynchronousNetworkFetcher fetcherWithUrl:[self request] delegate:self];
    NSLog(@"URL: %@", [[self request] absoluteString]);
    querying = YES;
}

- (void)cancel
{
    canceled = YES;
    querying = NO;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    if (!canceled) {
        querying = NO;
        NSString * response =
            [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]
            autorelease];
        NSLog(@"Received reverse geocode response: %@", response);
        NSError * error = nil;
        NSDictionary * responseDict = [response JSONValueOrError:&error];
        if (responseDict) {
            NSArray * placemarkArray =
                [responseDict objectForKey:@"Placemark"];
            NSDictionary * placemarkDict = [placemarkArray objectAtIndex:0];
            NSDictionary * addressDetailsDict =
                [placemarkDict objectForKey:@"AddressDetails"];
            NSMutableDictionary * countryDict =
                [addressDetailsDict objectForKey:@"Country"];

            NSString * countryName = [countryDict objectForKey:@"CountryName"];
            NSString * countryNameCode =
                [countryDict objectForKey:@"CountryNameCode"];

            NSDictionary * administrativeAreaDict =
                [countryDict objectForKey:@"AdministrativeArea"];
            NSString * abbreviatedAdminAreaName =
                [administrativeAreaDict objectForKey:@"AdministrativeAreaName"];
            NSString * fullAdminAreaName =
                [[[self class] stateAbbreviationMapping]
                objectForKey:abbreviatedAdminAreaName];
            NSString * administrativeAreaName =
                ([countryNameCode isEqual:@"US"] ||
                [countryNameCode isEqual:@"USA"]) &&
                fullAdminAreaName ?
                fullAdminAreaName : abbreviatedAdminAreaName;

            NSDictionary * subAdministrativeAreaDict =
                [administrativeAreaDict objectForKey:@"SubAdministrativeArea"];
            NSString * subAdministrativeAreaName =
                [subAdministrativeAreaDict
                objectForKey:@"SubAdministrativeAreaName"];
            NSDictionary * localityDict =
                [subAdministrativeAreaDict objectForKey:@"Locality"];
            NSString * localityName =
                [localityDict objectForKey:@"LocalityName"];
            NSDictionary * postalCodeDict =
                [localityDict objectForKey:@"PostalCode"];
            NSString * postalCodeName =
                [postalCodeDict objectForKey:@"PostalCodeNumber"];
            NSDictionary * thoroughfareDict =
                [localityDict objectForKey:@"Thoroughfare"];
            NSString * thoroughfareName =
                [thoroughfareDict objectForKey:@"ThoroughfareName"];
            NSString * addressBookSubThoroughfareName =
                thoroughfareName ?
                [thoroughfareName stringByMatching:@"[0-9]+\\-[0-9]+"] : nil;
            NSString * addressBookThoroughfareName =
                thoroughfareName ?
                [thoroughfareName
                stringByReplacingOccurrencesOfRegex:@"[0-9]+\\-[0-9]+ "
                withString:@""] :
                nil;

            NSMutableDictionary * addressDict =
                [NSMutableDictionary dictionary];
            if (localityName)
                [addressDict setObject:localityName forKey:@"City"];
            if (countryName)
                [addressDict setObject:countryName forKey:@"Country"];
            if (countryNameCode)
                [addressDict setObject:countryNameCode forKey:@"CountryCode"];
            if (administrativeAreaName)
                [addressDict setObject:administrativeAreaName forKey:@"State"];
            if (subAdministrativeAreaName)
                [addressDict setObject:subAdministrativeAreaName
                    forKey:@"SubAdministrativeArea"];
            if (addressBookThoroughfareName)
                [addressDict setObject:addressBookThoroughfareName
                    forKey:@"Thoroughfare"];
            if (addressBookSubThoroughfareName)
                [addressDict setObject:addressBookSubThoroughfareName
                    forKey:@"SubThoroughfare"];
            if (thoroughfareName)
                [addressDict setObject:thoroughfareName forKey:@"Street"];
            if (postalCodeName)
                [addressDict setObject:postalCodeName forKey:@"ZIP"];
            MKPlacemark * placemark =
                [[[MKPlacemark alloc]
                initWithCoordinate:self.coordinate
                addressDictionary:addressDict]
                autorelease];
            [delegate reverseGeocoder:self didFindPlacemark:placemark];
        } else
            [delegate reverseGeocoder:self didFailWithError:error];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    if (!canceled) {
        querying = NO;
        [delegate reverseGeocoder:self didFailWithError:error];
    }
}

- (NSURL *)request
{
    NSString * apiKey =
        [[InfoPlistConfigReader reader] valueForKey:@"GoogleMapsApiKey"];
    NSString * urlString =
        [NSString stringWithFormat:
        @"http://maps.google.com/maps/geo?q=%f,%f&output=json&oe=utf8&sensor=false&key=%@",
        coordinate.latitude, coordinate.longitude, apiKey];

    return [NSURL URLWithString:urlString];
}

+ (NSDictionary *)stateAbbreviationMapping
{
    if (!stateAbbreviationMapping) {
        stateAbbreviationMapping = [[NSMutableDictionary dictionary] retain];
        [stateAbbreviationMapping setObject:@"Alabama" forKey:@"AL"];
        [stateAbbreviationMapping setObject:@"Alaska" forKey:@"AK"];
        [stateAbbreviationMapping setObject:@"Arizona" forKey:@"AZ"];
        [stateAbbreviationMapping setObject:@"Arkansas" forKey:@"AR"];
        [stateAbbreviationMapping setObject:@"California" forKey:@"CA"];
        [stateAbbreviationMapping setObject:@"Colorado" forKey:@"CO"];
        [stateAbbreviationMapping setObject:@"Connecticut" forKey:@"CT"];
        [stateAbbreviationMapping setObject:@"Delaware" forKey:@"DE"];
        [stateAbbreviationMapping setObject:@"Florida" forKey:@"FL"];
        [stateAbbreviationMapping setObject:@"Georgia" forKey:@"GA"];
        [stateAbbreviationMapping setObject:@"Hawaii" forKey:@"HI"];
        [stateAbbreviationMapping setObject:@"Idaho" forKey:@"ID"];
        [stateAbbreviationMapping setObject:@"Illinois" forKey:@"IL"];
        [stateAbbreviationMapping setObject:@"Indiana" forKey:@"IN"];
        [stateAbbreviationMapping setObject:@"Iowa" forKey:@"IA"];
        [stateAbbreviationMapping setObject:@"Kansas" forKey:@"KS"];
        [stateAbbreviationMapping setObject:@"Kentucky" forKey:@"KY"];
        [stateAbbreviationMapping setObject:@"Louisiana" forKey:@"LA"];
        [stateAbbreviationMapping setObject:@"Maine" forKey:@"ME"];
        [stateAbbreviationMapping setObject:@"Maryland" forKey:@"MD"];
        [stateAbbreviationMapping setObject:@"Massachusetts" forKey:@"MA"];
        [stateAbbreviationMapping setObject:@"Michigan" forKey:@"MI"];
        [stateAbbreviationMapping setObject:@"Minnesota" forKey:@"MN"];
        [stateAbbreviationMapping setObject:@"Mississippi" forKey:@"MS"];
        [stateAbbreviationMapping setObject:@"Missouri" forKey:@"MO"];
        [stateAbbreviationMapping setObject:@"Montana" forKey:@"MT"];
        [stateAbbreviationMapping setObject:@"Nebraska" forKey:@"NE"];
        [stateAbbreviationMapping setObject:@"Nevada" forKey:@"NV"];
        [stateAbbreviationMapping setObject:@"New Hampshire" forKey:@"NH"];
        [stateAbbreviationMapping setObject:@"New Jersey" forKey:@"NJ"];
        [stateAbbreviationMapping setObject:@"New Mexico" forKey:@"NM"];
        [stateAbbreviationMapping setObject:@"New York" forKey:@"NY"];
        [stateAbbreviationMapping setObject:@"North Carolina" forKey:@"NC"];
        [stateAbbreviationMapping setObject:@"North Dakota" forKey:@"ND"];
        [stateAbbreviationMapping setObject:@"Ohio" forKey:@"OH"];
        [stateAbbreviationMapping setObject:@"Oklahoma" forKey:@"OK"];
        [stateAbbreviationMapping setObject:@"Oregon" forKey:@"OR"];
        [stateAbbreviationMapping setObject:@"Pennsylvania" forKey:@"PA"];
        [stateAbbreviationMapping setObject:@"Rhode Island" forKey:@"RI"];
        [stateAbbreviationMapping setObject:@"South Carolina" forKey:@"SC"];
        [stateAbbreviationMapping setObject:@"South Dakota" forKey:@"SD"];
        [stateAbbreviationMapping setObject:@"Tennessee" forKey:@"TN"];
        [stateAbbreviationMapping setObject:@"Texas" forKey:@"TX"];
        [stateAbbreviationMapping setObject:@"Utah" forKey:@"UT"];
        [stateAbbreviationMapping setObject:@"Vermont" forKey:@"VT"];
        [stateAbbreviationMapping setObject:@"Virginia" forKey:@"VA"];
        [stateAbbreviationMapping setObject:@"Washington" forKey:@"WA"];
        [stateAbbreviationMapping setObject:@"West Virginia" forKey:@"WV"];
        [stateAbbreviationMapping setObject:@"Wisconsin" forKey:@"WI"];
        [stateAbbreviationMapping setObject:@"Wyoming" forKey:@"WY"];
    }

    return stateAbbreviationMapping;
}

@end
