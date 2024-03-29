//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoDataViewController.h"
#import "NetworkAwareViewControllerDelegate.h"

typedef enum
{
    kConnectedAndUpdating,
    kConnectedAndNotUpdating,
    kDisconnected
} UpdatingState;

@interface NetworkAwareViewController : UIViewController
{
    IBOutlet NSObject<NetworkAwareViewControllerDelegate> * delegate;

    IBOutlet UIViewController * targetViewController;
    NoDataViewController * noDataViewController;

    NSInteger updatingState;
    BOOL cachedDataAvailable;

    NSString * updatingText;
    NSString * loadingText;
    NSString * noConnectionText;

    UIView * updatingView;

    BOOL visible;
    BOOL transparentUpdatingViewEnabled;
}

@property (nonatomic, retain)
    NSObject<NetworkAwareViewControllerDelegate> * delegate;
@property (nonatomic, retain) UIViewController * targetViewController;
@property (nonatomic) BOOL cachedDataAvailable;
@property (nonatomic, assign) BOOL transparentUpdatingViewEnabled;

- (id)initWithTargetViewController:(UIViewController *)targetViewController;

- (void)setUpdatingState:(NSInteger)state;
- (void)setCachedDataAvailable:(BOOL)available;

- (void)setUpdatingText:(NSString *)text;
- (void)setLoadingText:(NSString *)text;
- (void)setNoConnectionText:(NSString *)text;

@end
