//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsTableViewCell.h"
#import "UIColor+TwitchColors.h"

@implementation AccountsTableViewCell

@synthesize accountSelected;

- (void)dealloc
{
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    return (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]);
}

#pragma mark State transitions

- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    [super willTransitionToState:state];

    if (self.accountSelected)
       if (state & UITableViewCellStateEditingMask)
           self.textLabel.textColor = [UIColor blackColor];
       else
           self.textLabel.textColor = [UIColor twitchCheckedColor];
}

#pragma mark Managing the display

- (void)updateDisplay:(BOOL)isEditing
{
    if (isEditing)
        self.textLabel.textColor = [UIColor blackColor];
    else
        self.textLabel.textColor =
            self.accountSelected ?
            [UIColor twitchCheckedColor] : [UIColor blackColor];

    self.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.accessoryType =
        self.accountSelected ?
        UITableViewCellAccessoryCheckmark :
        UITableViewCellAccessoryNone;
}

#pragma mark Accessors

- (void)setAccountSelected:(BOOL)selected
{
    accountSelected = selected;

    [self updateDisplay:self.editing];
}

@end
