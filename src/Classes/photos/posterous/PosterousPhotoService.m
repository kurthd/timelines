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

+ (ASIHTTPRequest *)requestForMedia:(NSData *)media
                                url:(NSURL *)url
                           username:(NSString *)username
                           password:(NSString *)password
                             source:(NSString *)source
                         sourceLink:(NSString *)sourceLink;
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

    return [[self class] requestForMedia:imageData
                                     url:[NSURL URLWithString:self.posterousUrl]
                                username:ctls.username
                                password:ctls.password
                                  source:[[self class] source]
                              sourceLink:[[self class] sourceLink]];
}

- (ASIHTTPRequest *)requestForUploadingVideo:(NSData *)videoData
                             withCredentials:(PosterousCredentials *)ctls
{
    return [[self class] requestForMedia:videoData
                                     url:[NSURL URLWithString:self.posterousUrl]
                                username:ctls.username
                                password:ctls.password
                                  source:[[self class] source]
                              sourceLink:[[self class] sourceLink]];
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

- (void)processVideoUploadResponse:(NSData *)response
{
    [self.parser parse:response];

    if (self.parser.error) {
        NSError * error =
            [NSError errorWithLocalizedDescription:self.parser.error];
        [self.delegate service:self failedToPostImage:error];
    } else
        [self.delegate service:self didPostVideoToUrl:self.parser.mediaUrl];
}

- (void)processImageUploadFailure:(NSError *)error
{
    [self.delegate service:self failedToPostImage:error];
}

- (void)processVideoUploadFailure:(NSError *)error
{
    [self.delegate service:self failedToPostVideo:error];
}

#pragma mark Private implementation

+ (ASIHTTPRequest *)requestForMedia:(NSData *)media
                                url:(NSURL *)url
                           username:(NSString *)username
                           password:(NSString *)password
                             source:(NSString *)source
                         sourceLink:(NSString *)sourceLink
{
    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:url];

    [req setPostValue:username forKey:@"username"];
    [req setPostValue:password forKey:@"password"];
    [req setPostValue:source forKey:@"source"];
    [req setPostValue:sourceLink forKey:@"sourceLink"];
    [req setData:media forKey:@"media"];

    return [req autorelease];
}

+ (NSString *)source
{
    return @"Twitbit for iPhone";
}

+ (NSString *)sourceLink
{
    return @"http://twitbitapp.com";
}

@end
