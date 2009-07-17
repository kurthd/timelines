//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "RemotePhoto.h"

@implementation RemotePhoto

@synthesize image, url, name;

- (void)dealloc
{
    [image release];
    [url release];
    [name release];
    [super dealloc];
}

- (id)initWithImage:(UIImage *)anImage url:(NSString *)aUrl
    name:(NSString *)aName
{
    if (self = [super init]) {
        self.image = anImage;
        url = [aUrl copy];
        name = [aName copy];
    }

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{url: %@, name: %@}", self.url,
        self.name];
}

- (BOOL)isEqual:(id)otherObject
{
    RemotePhoto * otherRemotePhoto = (RemotePhoto *)otherObject;

    return otherRemotePhoto && [self.url isEqual:otherRemotePhoto.url];
}

@end
