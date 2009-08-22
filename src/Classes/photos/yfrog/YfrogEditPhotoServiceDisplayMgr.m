//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "YfrogEditPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"
#import "YfrogCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface YfrogEditPhotoServiceDisplayMgr ()

@property (nonatomic, retain) YfrogCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) YfrogSettingsViewController * viewController;

@end

@implementation YfrogEditPhotoServiceDisplayMgr

@synthesize credentials, context;
@synthesize navigationController, viewController;

- (void)dealloc
{
    self.credentials = nil;
    self.context = nil;

    self.navigationController = nil;
    self.viewController = nil;

    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)someCredentials
              navigationController:(UINavigationController *)aController
                           context:(NSManagedObjectContext *)aContext
{
    NSAssert1([someCredentials isKindOfClass:[YfrogCredentials class]],
        @"Expected yfrog credentials, but got: %@", [someCredentials class]);

    self.credentials = (YfrogCredentials *) someCredentials;
    self.context = aContext;
    self.navigationController = aController;

    self.viewController.credentials = self.credentials;
    [self.navigationController pushViewController:self.viewController
                                         animated:YES];
}

#pragma mark YfrogSettingsViewControllerDelegate implementation

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password
{
    if (![username isEqualToString:self.credentials.username] ||
        ![password isEqualToString:[self.credentials password]]) {
        // authenticate the user
        TwitterBasicAuthAuthenticator * auth =
            [[TwitterBasicAuthAuthenticator alloc] init];
        auth.delegate = self;
        [auth authenticateUsername:username password:password];

        [self.viewController disable];
    } else
        [self userDidCancel];
}

- (void)userDidCancel
{
    [self.navigationController popViewControllerAnimated:YES];
    self.viewController = nil;
}

- (void)deleteServiceWithCredentials:(YfrogCredentials *)toDelete
{
    [self.navigationController popViewControllerAnimated:YES];
    self.viewController = nil;

    [self.delegate userWillDeleteAccountWithCredentials:toDelete];
    [toDelete.credentials removePhotoServiceCredentialsObject:toDelete];
    [self.context deleteObject:toDelete];
    [self.delegate userDidDeleteAccount];
}

#pragma mark TwitterBasicAuthAuthenticatorDelegate implementation

- (void)authenticator:(TwitterBasicAuthAuthenticator *)authenticator
    didAuthenticateUsername:(NSString *)username password:(NSString *)password
{
    [self.navigationController popViewControllerAnimated:YES];
    self.viewController = nil;

    // save the new credentials
    self.credentials.username = username;
    [self.credentials setPassword:password];

    [authenticator autorelease];
}

- (void)authenticator:(TwitterBasicAuthAuthenticator *)authenticator
    didFailToAuthenticateUsername:(NSString *)username
                         password:(NSString *)password
                            error:(NSError *)error
{
    NSString * title = NSLocalizedString(@"login.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    
    [authenticator autorelease];

    [self.viewController enable];
}

#pragma mark Accessors

- (YfrogSettingsViewController *)viewController
{
    if (!viewController) {
        viewController =
            [[YfrogSettingsViewController alloc]
            initWithNibName:@"YfrogSettingsView" bundle:nil];
        viewController.delegate = self;
    }

    return viewController;
}

@end
