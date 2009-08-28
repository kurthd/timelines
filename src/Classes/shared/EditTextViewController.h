//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditTextViewControllerDelegate

- (void)userDidSetText:(NSString *)text;

@end

@interface EditTextViewController : UITableViewController <UITextFieldDelegate>
{
    id<EditTextViewControllerDelegate> delegate;

    IBOutlet UITableViewCell * textFieldCell;
    IBOutlet UITextField * textField;

    NSString * viewTitle;
}

@property (nonatomic, assign) id<EditTextViewControllerDelegate> delegate;
@property (nonatomic, retain, readonly) UITextField * textField;
@property (nonatomic, copy) NSString * viewTitle;

- (id)initWithDelegate:(id<EditTextViewControllerDelegate>)aDelegate;

@end
