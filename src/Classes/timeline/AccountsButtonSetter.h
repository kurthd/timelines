//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsButton.h"
#import "TwitterService.h"
#import "AsynchronousNetworkFetcher.h"

@interface AccountsButtonSetter :
    NSObject <TwitterServiceDelegate, AsynchronousNetworkFetcherDelegate>
{
    AccountsButton * accountsButton;
    TwitterService * twitterService;
    NSManagedObjectContext * context;

    NSString * username;
}

- (id)initWithAccountsButton:(AccountsButton *)accountsButton
    twitterService:(TwitterService *)twitterService
                     context:(NSManagedObjectContext *)aContext;

- (void)setButtonWithUsername:(NSString *)username;

@end
