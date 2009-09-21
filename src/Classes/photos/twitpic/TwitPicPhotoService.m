//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicPhotoService.h"
#import "TwitPicResponseParser.h"
#import "NSError+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitPicCredentials+KeychainAdditions.h"
#import "InfoPlistConfigReader.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@interface TwitPicPhotoService ()

@property (nonatomic, copy) NSString * twitPicUrl;

@property (nonatomic, retain) TwitPicResponseParser * parser;

+ (NSString *)devKey;

@end

@implementation TwitPicPhotoService

@synthesize twitPicUrl;
@synthesize parser;

- (void)dealloc
{
    self.twitPicUrl = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.twitPicUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"TwitPicPostUrl"];
        parser = [[TwitPicResponseParser alloc] init];
        queue = [[ASINetworkQueue alloc] init];
    }

    return self;
}

- (ASIHTTPRequest *)requestForUploadingImage:(UIImage *)anImage
                             withCredentials:(TwitPicCredentials *)ctls
{
    NSData * imageData = [self dataForImageUsingCompressionSettings:anImage];
    NSString * username = ctls.username;
    NSString * password = ctls.password;

    NSURL * url = [NSURL URLWithString:self.twitPicUrl];

    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:url];

    [req setPostValue:[[self class] devKey] forKey:@"key"];
    [req setPostValue:username forKey:@"username"];
    [req setPostValue:password forKey:@"password"];
    [req setData:imageData forKey:@"media"];

    return [req autorelease];
}

- (void)sendVideo:(NSData *)aVideo
  withCredentials:(TwitPicCredentials *)ctls
{
    NSAssert(
        NO, @"Trying to send a video via TwitPic, which does not support it.");
}

#pragma mark Private implementation

- (void)processImageUploadResponse:(NSData *)response
{
    [self.parser parse:response];

    if (self.parser.error) {
        NSError * error =
            [NSError errorWithLocalizedDescription:self.parser.error];
        [self.delegate service:self failedToPostImage:error];
    } else
        [self.delegate service:self didPostImageToUrl:self.parser.mediaUrl];
}

- (void)processImageUploadFailure:(NSError *)error
{
    if (!([error.domain isEqualToString:NetworkRequestErrorDomain] &&
        error.code == ASIRequestCancelledErrorType)) {
        NSLog(@"Received error: %@", error);
        [self.delegate service:self failedToPostImage:error];
    }
}

#pragma mark Private implementation

+ (NSString *)devKey
{
    return @"023AGLTUc7533b166461ddb3bc523c54ab082240";
}

@end
