//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DirectMessage+GeneralHelpers.h"
#import "Tweet+GeneralHelpers.h"

@implementation DirectMessage (GeneralHelpers)

- (NSString *)textAsHtml
{
    return [Tweet tweetTextAsHtml:self.text timestamp:self.created source:nil];
}

@end