//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "PhotoServiceCredentials.h"

@interface TwitterCredentials (PhotoServiceAdditions)

- (PhotoServiceCredentials *)defaultPhotoServiceCredentials;
- (PhotoServiceCredentials *)defaultVideoServiceCredentials;

@end