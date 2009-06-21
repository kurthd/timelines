//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "User.h"

@interface User ()

@property (nonatomic, copy) NSString * name;

@end

@implementation User

@synthesize name;

- (void)dealloc
{
    self.name = nil;
    [super dealloc];
}

- (id)initWithName:(NSString *)aName
{
    if (self = [super init])
        self.name = aName;

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

@end
