//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousNetworkFetcherDelegate.h"
#import "AsynchronousNetworkFetcher.h"

@interface LocationCellView : UIView <AsynchronousNetworkFetcherDelegate>
{
    NSString * locationText;
    BOOL highlighted;
    UIImage * mapImage;
    UIActivityIndicatorView * activityIndicator;
    BOOL updatingMap;
    UIColor * textColor;
    BOOL landscape;
    AsynchronousNetworkFetcher * impageUrlFetcher;
}

@property (nonatomic, copy) NSString * locationText;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, retain) UIColor * textColor;

@end