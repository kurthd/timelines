//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PosterousPhotoService.h"
#import "PosterousResponseParser.h"
#import "NSError+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "PosterousCredentials+KeychainAdditions.h"
#import "InfoPlistConfigReader.h"
#import "ASIFormDataRequest.h"

@interface PosterousPhotoService ()

@property (nonatomic, copy) NSString * posterousUrl;

@property (nonatomic, retain) PosterousResponseParser * parser;

+ (NSString *)source;
+ (NSString *)sourceLink;

@end

@implementation PosterousPhotoService

@synthesize posterousUrl;
@synthesize parser;

- (void)dealloc
{
    self.posterousUrl = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.posterousUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"PosterousPostUrl"];
        parser = [[PosterousResponseParser alloc] init];
    }

    return self;
}

- (ASIHTTPRequest *)requestForUploadingImage:(UIImage *)anImage
                             withCredentials:(PosterousCredentials *)ctls
{
    NSData * imageData = [self dataForImageUsingCompressionSettings:anImage];
    NSString * username = ctls.username;
    NSString * password = ctls.password;

    NSURL * url = [NSURL URLWithString:self.posterousUrl];

    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:url];

    [req setPostValue:username forKey:@"username"];
    [req setPostValue:password forKey:@"password"];
    [req setPostValue:[[self class] source] forKey:@"source"];
    [req setPostValue:[[self class] sourceLink] forKey:@"sourceLink"];
    [req setData:imageData forKey:@"media"];

    return [req autorelease];
}

- (void)sendVideo:(NSData *)aVideo
  withCredentials:(PosterousCredentials *)ctls
{
    NSAssert(NO,
        @"Trying to send a video via Posterous, which does not support it.");
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
    [self.delegate service:self failedToPostImage:error];
}

#pragma mark Private implementation

+ (NSString *)source
{
    return @"Twitbit for iPhone";
}

+ (NSString *)sourceLink
{
    return @"http://twitbitapp.com";
}

@end
