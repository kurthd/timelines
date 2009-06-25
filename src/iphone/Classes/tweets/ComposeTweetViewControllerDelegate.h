//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ComposeTweetViewControllerDelegate

- (void)userDidSave:(NSString *)text;
- (void)userDidCancel;

- (void)userWantsToSelectPhoto;

@end
