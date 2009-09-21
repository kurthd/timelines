//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"
#import "TwitVid.h"  // for TwitVidDelegate

@interface TwitVidPhotoService : PhotoService <TwitVidDelegate>
{
    TwitVid * twitVid;
    TwitVidRequest * request;
}

@end
