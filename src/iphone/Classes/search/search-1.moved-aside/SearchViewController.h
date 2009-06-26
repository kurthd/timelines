//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchViewControllerDelegate.h"

@interface SearchViewController : NSObject
{
    id<SearchViewControllerDelegate> delegate;
}

@property (nonatomic, assign) id<SearchViewControllerDelegate> id;

@end
