//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoServiceSelectorViewControllerDelegate

- (NSDictionary *)photoServices;
- (void)userSelectedServiceNamed:(NSString *)serviceName;

@end

@interface PhotoServiceSelectorViewController : UITableViewController
{
    id<PhotoServiceSelectorViewControllerDelegate> delegate;

    NSArray * names;
    NSArray * logos;
}

@property (nonatomic, assign) id<PhotoServiceSelectorViewControllerDelegate>
    delegate;

@end
