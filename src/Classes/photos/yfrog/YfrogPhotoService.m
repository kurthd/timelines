//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "YfrogPhotoService.h"
#import "YfrogResponseParser.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "YfrogCredentials+KeychainAdditions.h"
#import "InfoPlistConfigReader.h"
#import "NSError+InstantiationAdditions.h"
#import "ASIFormDataRequest.h"

@interface YfrogPhotoService ()

@property (nonatomic, copy) NSString * yfrogUrl;

@property (nonatomic, retain) YfrogResponseParser * parser;

- (ASIHTTPRequest *)requestForUploadingData:(NSData *)data
                                 ofMimeType:(NSString *)mimeType
                            withCredentials:(YfrogCredentials *)ctls;
+ (NSString *)devKey;

@end

@implementation YfrogPhotoService

@synthesize yfrogUrl;
@synthesize parser;

- (void)dealloc
{
    self.yfrogUrl = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.yfrogUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"YfrogPostUrl"];
        parser = [[YfrogResponseParser alloc] init];
    }

    return self;
}

#pragma mark Public Implementation

- (ASIHTTPRequest *)requestForUploadingImage:(UIImage *)anImage
                             withCredentials:(YfrogCredentials *)ctls
{
    NSData * imageData = [self dataForImageUsingCompressionSettings:image];
    NSString * mimeType = [self mimeTypeForImage:image];

    return [self requestForUploadingData:imageData
                              ofMimeType:mimeType
                         withCredentials:ctls];
}

- (ASIHTTPRequest *)requestForUploadingVideo:(NSData *)videoData
                             withCredentials:(YfrogCredentials *)ctls
{
    return [self requestForUploadingData:videoData
                              ofMimeType:@"video/quicktime"
                         withCredentials:ctls];
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

- (ASIHTTPRequest *)requestForUploadingData:(NSData *)data
                                 ofMimeType:(NSString *)mimeType
                            withCredentials:(YfrogCredentials *)ctls
{
    NSURL * url = [NSURL URLWithString:self.yfrogUrl];

    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:url];

    [req setPostValue:[[self class] devKey] forKey:@"key"];
    [req setPostValue:ctls.username forKey:@"username"];
    [req setPostValue:ctls.password forKey:@"password"];
    [req setData:data withFileName:@"file"
        andContentType:mimeType forKey:@"media"];

    return [req autorelease];
}

+ (NSString *)devKey
{
    return @"023AGLTUc7533b166461ddb3bc523c54ab082240";
}

@end
