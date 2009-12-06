//
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PhotoSourceDelegate

- (void)fetchedImage:(UIImage *)image withUrl:(NSString *)url;
- (void)failedToFetchImageWithUrl:(NSString *)url error:(NSError *)error;
- (void)unableToFindImageForUrl:(NSString *)url;
- (void)progressOfImageFetch:(double)percentComplete;

@end
