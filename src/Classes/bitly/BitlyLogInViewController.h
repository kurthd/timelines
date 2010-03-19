//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BitlyLogInViewControllerDelegate
- (void)userDidSave:(NSString *)username apiKey:(NSString *)apiKey;
- (void)userDidCancel;

- (void)deleteAccount:(NSString *)username;
@end

@interface BitlyLogInViewController :
    UITableViewController <UIActionSheetDelegate>
{
    id<BitlyLogInViewControllerDelegate> delegate;

    NSString * username;
    NSString * apiKey;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * apiKeyCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * apiKeyTextField;

    //BitlyLogInViewControllerDisplayMode displayMode;

    //BOOL displayingActivity;
    BOOL editingExistingAccount;
}

@property (nonatomic, assign) id<BitlyLogInViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL editingExistingAccount;

//@property (nonatomic, assign) BOOL editingExistingAccount;

- (id)initWithUsername:(NSString *)username apiKey:(NSString *)apiKey;

#pragma mark Button actions

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
