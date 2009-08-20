//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServiceCredentials.h"

@protocol EditPhotoServiceDisplayMgrDelegate

- (void)userWillDeleteAccountWithCredentials:(PhotoServiceCredentials *)cdlts;
- (void)userDidDeleteAccount;

@end

@interface EditPhotoServiceDisplayMgr : NSObject
{
    id<EditPhotoServiceDisplayMgrDelegate> delegate;
}

@property (nonatomic, assign) id<EditPhotoServiceDisplayMgrDelegate> delegate;

+ (id)editServiceDisplayMgrWithServiceName:(NSString *)serviceName;

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
