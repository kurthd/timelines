//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ComposeTweetViewControllerDelegate

- (void)userWantsToSendTweet:(NSString *)text;
- (void)userWantsToSendDirectMessage:(NSString *)text
                         toRecipient:(NSString *)recipient;

- (void)userDidSaveTweetDraft:(NSString *)text
                  dismissView:(BOOL)dismissView;
- (void)userDidSaveDirectMessageDraft:(NSString *)text
                          toRecipient:(NSString *)recipient
                          dismissView:(BOOL)dismissView;

- (void)userDidCancelComposingTweet:(NSString *)text;
- (void)userDidCancelComposingDirectMessage:(NSString *)text
                                toRecipient:(NSString *)recipient;

- (void)userWantsToSelectPhoto;

- (void)userDidCancelActivity;

@end
