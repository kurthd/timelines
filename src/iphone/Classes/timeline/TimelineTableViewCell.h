//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h";

@interface TimelineTableViewCell : UITableViewCell
{
    IBOutlet RoundedImage * avatar;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * dateLabel;
    IBOutlet UILabel * tweetTextLabel;
}

- (void)setAvatarImage:(UIImage *)image;
- (void)setName:(NSString *)name;
- (void)setDate:(NSDate *)date;
- (void)setTweetText:(NSString *)tweetText;

+ (CGFloat)heightForContent:(NSString *)tweetText;

@end
