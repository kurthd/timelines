//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"
#import "TwitVid.h"

@interface TwitVidPhotoService : PhotoService <TwitVidDelegate>
{
    TwitVid * twitVid;
}

@end
