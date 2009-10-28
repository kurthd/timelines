//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToggleViewController : UIViewController
{
    IBOutlet UIViewController * childController;
}

@property (nonatomic, retain) UIViewController * childController;

@end
