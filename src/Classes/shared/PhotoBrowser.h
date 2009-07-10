//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemotePhoto.h"

@interface PhotoBrowser : UIViewController
{
    IBOutlet UIImageView * photoView;

    NSMutableArray * photoList;
}

@property (nonatomic, readonly) NSMutableArray * photoList;

- (IBAction)done:(id)sender;

- (void)addRemotePhoto:(RemotePhoto *)remotePhoto;
- (void)setIndex:(NSUInteger)index;

@end
