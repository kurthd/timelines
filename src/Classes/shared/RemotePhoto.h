//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RemotePhoto : NSObject
{
    UIImage * image;
    NSString * url;
    NSString * name;
}

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSString * name;

- (id)initWithImage:(UIImage *)image url:(NSString *)url name:(NSString *)name;

@end
