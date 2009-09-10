//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "InstapaperService.h"
#import "InfoPlistConfigReader.h"
#import "InstapaperCredentials+KeychainAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@interface InstapaperService ()

@property (nonatomic, copy) NSString * authenticationUrl;
@property (nonatomic, copy) NSString * postUrl;

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, copy) NSString * urlToAdd;

@property (nonatomic, retain) NSURLConnection * authenticationConnection;
@property (nonatomic, retain) NSURLConnection * postUrlConnection;

- (void)cleanUpAuthenticationConnection;
- (void)cleanUpPostUrlConnection;

@end

@implementation InstapaperService

@synthesize delegate, credentials, authenticationUrl, postUrl;
@synthesize username, password, urlToAdd;
@synthesize authenticationConnection, postUrlConnection;

- (void)dealloc
{
    self.delegate = nil;
    self.credentials = nil;

    self.authenticationUrl = nil;
    self.postUrl = nil;

    self.username = nil;
    self.password = nil;
    self.urlToAdd = nil;

    self.authenticationConnection = nil;
    self.postUrlConnection = nil;

    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        InfoPlistConfigReader * reader = [InfoPlistConfigReader reader];

        self.authenticationUrl =
            [reader valueForKey:@"InstapaperAuthenticationUrl"];
        self.postUrl = [reader valueForKey:@"InstapaperPostUrl"];
    }

    return self;
}

#pragma mark Authenticating a user

- (void)authenticateUsername:(NSString *)user password:(NSString *)pass
{
    self.username = user;
    self.password = pass;

    static NSString * allowed = @":@/?&";
    NSString * fullUrl =
        [NSString stringWithFormat:@"%@/?username=%@&password=%@",
        self.authenticationUrl,
        [self.username urlEncodedStringWithEscapedAllowedCharacters:allowed],
        [self.password urlEncodedStringWithEscapedAllowedCharacters:allowed]];

    NSURL * instapaperUrl = [NSURL URLWithString:fullUrl];
    NSURLRequest * request = [NSURLRequest requestWithURL:instapaperUrl];
    self.authenticationConnection =
        [NSURLConnection connectionWithRequest:request delegate:self];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)cancelAuthentication
{
    if (self.authenticationConnection) {
        [self.authenticationConnection cancel];
        [self cleanUpAuthenticationConnection];
    }
}

#pragma mark Saving URLs

- (void)addUrl:(NSString *)url
{
    self.urlToAdd = url;
    NSLog(@"Saving '%@' to Instapaper.", self.urlToAdd);

    static NSString * allowed = @":@/?&";
    NSString * user = self.credentials.username;
    NSString * pass =
        [self.credentials password] ? [self.credentials password] : @"";

    NSString * fullUrl =
        [NSString
        stringWithFormat:@"%@?url=%@&username=%@&password=%@&auto-title=1 ",
        self.postUrl,
        [self.urlToAdd urlEncodedStringWithEscapedAllowedCharacters:allowed],
        [user urlEncodedStringWithEscapedAllowedCharacters:allowed],
        [pass urlEncodedStringWithEscapedAllowedCharacters:allowed]];

    NSURL * instapaperUrl = [NSURL URLWithString:fullUrl];
    NSURLRequest * request = [NSURLRequest requestWithURL:instapaperUrl];
    self.postUrlConnection =
        [NSURLConnection connectionWithRequest:request delegate:self];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

#pragma mark NSURLConnectionDelegate implementation

- (void)connection:(NSURLConnection *)connection
    didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
    NSInteger statusCode = [httpResponse statusCode];
    NSLog(@"Instapaper response: %d: %@.", statusCode,
        [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);

    if (statusCode == 200 && connection == self.authenticationConnection) {
        SEL sel = @selector(authenticatedUsername:password:);
        if ([self.delegate respondsToSelector:sel])
            [self.delegate authenticatedUsername:self.username
                                        password:self.password];
    } else if (statusCode == 201 && connection == self.postUrlConnection) {
        SEL sel = @selector(postedUrl:);
        if ([self.delegate respondsToSelector:sel])
            [self.delegate postedUrl:self.urlToAdd];
    } else {
        NSString * errorMessage = nil;
        switch (statusCode) {
            case 400:
                errorMessage =
                    NSLocalizedString(@"instapaper.http400.message", @"");
                break;
            case 403:
                errorMessage =
                    NSLocalizedString(@"instapaper.http403.message", @"");
                break;
            case 500:
                errorMessage =
                    NSLocalizedString(@"instapaper.http500.message", @"");
                break;
            default:
                errorMessage =
                    NSLocalizedString(@"instapaper.unknownerror.message", @"");
                break;
        }

        NSError * error =
                [NSError errorWithLocalizedDescription:errorMessage];
        if (connection == self.authenticationConnection) {
            SEL sel = @selector(failedToAuthenticateUsername:password:error:);
            if ([self.delegate respondsToSelector:sel])
                [self.delegate failedToAuthenticateUsername:self.username
                                                   password:self.password
                                                      error:error];
        } else if (connection == self.postUrlConnection) {
            SEL sel = @selector(failedToPostUrl:error:);
            if ([self.delegate respondsToSelector:sel])
                [self.delegate failedToPostUrl:self.postUrl error:error];
        }
    }
}

- (void)connection:(NSURLConnection *)connection
    didFailWithError:(NSError *)error
{
    if (connection == self.authenticationConnection) {
        [self cleanUpAuthenticationConnection];
        [[UIApplication sharedApplication] networkActivityDidFinish];
    } else if (connection == self.postUrlConnection) {
        [self cleanUpPostUrlConnection];
        [[UIApplication sharedApplication] networkActivityDidFinish];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (connection == self.authenticationConnection) {
        [self cleanUpAuthenticationConnection];
        [[UIApplication sharedApplication] networkActivityDidFinish];
    } else if (connection == self.postUrlConnection) {
        [self cleanUpPostUrlConnection];
        [[UIApplication sharedApplication] networkActivityDidFinish];
    }
}

#pragma mark Private implementation

- (void)cleanUpAuthenticationConnection
{
    self.username = nil;
    self.password = nil;

    [authenticationConnection autorelease];
    authenticationConnection = nil;
}

- (void)cleanUpPostUrlConnection
{
    self.urlToAdd = nil;

    [postUrlConnection autorelease];
    postUrlConnection = nil;
}

@end
