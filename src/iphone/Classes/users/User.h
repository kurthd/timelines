//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject <NSCopying>
{
    NSString * name;
}

- (id)initWithName:(NSString *)aName;

@end
