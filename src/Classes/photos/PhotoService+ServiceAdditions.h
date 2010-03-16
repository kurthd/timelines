//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"

@interface PhotoService (ServiceAdditions)

+ (NSDictionary *)freePhotoServiceNamesAndLogos;
+ (NSDictionary *)premiumPhotoServiceNamesAndLogos;

+ (id)photoServiceWithServiceName:(NSString *)serviceName;

@end
