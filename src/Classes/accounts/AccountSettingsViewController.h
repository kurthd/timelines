//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountSettings.h"
#import "TwitterCredentials.h"
#import "TwitbitShared.h"

@protocol AccountSettingsViewControllerDelegate

- (void)userDidCommitSettings:(AccountSettings *)settings
                   forAccount:(TwitterCredentials *)credentials;

- (void)userWantsToConfigurePhotoServicesForAccount:
    (TwitterCredentials *)credentials;

- (void)userWantsToConfigureInstapaperForAccount:
    (TwitterCredentials *)credentials;
- (void)userWantsToConfigureBitlyForAccount:(TwitterCredentials *)credentials;

@end

@interface AccountSettingsViewController :
    UITableViewController <SelectionViewControllerDelegate>
{
    id<AccountSettingsViewControllerDelegate> delegate;

    IBOutlet UITableViewCell * pushMentionsCell;
    IBOutlet UITableViewCell * pushDirectMessagesCell;
    UITableViewCell * pushNotificationSoundCell;

    IBOutlet UISwitch * pushMentionsSwitch;
    IBOutlet UISwitch * pushDirectMessagesSwitch;

    NSArray * pushSettingTableViewCells;

    TwitterCredentials * credentials;
    AccountSettings * settings;

    SelectionViewController * soundSelector;

    NSArray * pushNotificationSounds;

    SoundPlayer * soundPlayer;
}

@property (nonatomic, retain) id<AccountSettingsViewControllerDelegate>
    delegate;

- (void)presentSettings:(AccountSettings *)someSettings
             forAccount:(TwitterCredentials *)someCredentials;

- (void)reloadDisplay;

@end
