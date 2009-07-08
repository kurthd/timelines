//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "ComposeTweetDisplayMgr.h"

@interface TimelineDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
}

- (id)initWithContext:(NSManagedObjectContext *)context;

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController title:(NSString *)title
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr;
    
@end
