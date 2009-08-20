//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicEditPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"
#import "TwitPicCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface TwitPicEditPhotoServiceDisplayMgr ()

@property (nonatomic, retain) TwitPicCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) TwitPicSettingsViewController * viewController;

@end

@implementation TwitPicEditPhotoServiceDisplayMgr

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
    NSAssert1([someCredentials isKindOfClass:[TwitPicCredentials class]],
        @"Expected twitpic credentials, but got: %@", [someCredentials class]);

    self.credentials = (TwitPicCredentials *) someCredentials;
    self.context = aContext;
    self.navigationController = aController;

    self.viewController.credentials = self.credentials;
    [self.navigationController pushViewController:self.viewController
                                         animated:YES];
}

#pragma mark TwitPicSettingsViewControllerDelegate implementation

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

- (void)deleteServiceWithCredentials:(TwitPicCredentials *)toDelete
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

- (TwitPicSettingsViewController *)viewController
{
    if (!viewController) {
        viewController =
            [[TwitPicSettingsViewController alloc]
            initWithNibName:@"TwitPicSettingsView" bundle:nil];
        viewController.delegate = self;
    }

    return viewController;
}

@end
