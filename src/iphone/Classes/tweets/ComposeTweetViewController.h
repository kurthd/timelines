//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposeTweetViewControllerDelegate.h"

@interface ComposeTweetViewController : UIViewController
{
    id<ComposeTweetViewControllerDelegate> delegate;

    IBOutlet UITextView * textView;

    IBOutlet UIBarButtonItem * sendButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UILabel * characterCount;
}

@property (nonatomic, assign) id<ComposeTweetViewControllerDelegate> delegate;

- (void)promptWithText:(NSString *)text;
- (void)addTextToMessage:(NSString *)text;

- (IBAction)userDidSave;
- (IBAction)userDidCancel;
- (IBAction)choosePhoto;

@end
