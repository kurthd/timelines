//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrPhotoService.h"
#import "FlickrCredentials.h"
#import "NSNumber+EncodingAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "RegexKitLite.h"
#import "NSArray+IterationAdditions.h"

@interface FlickrPhotoService ()

@property (nonatomic, retain) OFFlickrAPIContext * flickrContext;

@property (nonatomic, retain) OFFlickrAPIRequest * uploadRequest;
@property (nonatomic, retain) OFFlickrAPIRequest * editRequest;

- (void)setTitle:(NSString *)title ofMediaAtUrl:(NSString *)url
    credentials:(FlickrCredentials *)someCredentials;

+ (NSString *)shortPhotoIdFromUrl:(NSString *)urlString;
+ (NSString *)photoIdFromShortPhotoId:(NSString *)shortPhotoId;

@end

@implementation FlickrPhotoService

@synthesize flickrContext;
@synthesize uploadRequest, editRequest;

- (void)dealloc
{
    self.flickrContext = nil;

    self.uploadRequest = nil;
    self.editRequest = nil;

    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        NSString * key = [[self class] apiKey];
        NSString * secret = [[self class] sharedSecret];
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:key
                                                      sharedSecret:secret];

        settingPhotoTitle = NO;
        settingVideoTitle = NO;
    }

    return self;
}

#pragma mark Public Implementation

- (void)sendImage:(UIImage *)anImage
  withCredentials:(FlickrCredentials *)ctls
{
    [super sendImage:anImage withCredentials:ctls];
    [flickrContext setAuthToken:ctls.token];

    self.uploadRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
    [self.uploadRequest setDelegate:self];

    NSString * defaultTitle =
        NSLocalizedString(@"flickr.photo.title.default", @"");

    NSArray * flickrTags = [ctls.tags allObjects];
    NSArray * tagsAsStrings =
        [flickrTags arrayByTransformingObjectsUsingSelector:@selector(name)];

    // quote each tag
    NSMutableArray * quotedTags =
        [NSMutableArray arrayWithCapacity:tagsAsStrings.count];
    for (NSString * tag in tagsAsStrings) {
        NSMutableString * quotedTag = [tag mutableCopy];
        [quotedTag insertString:@"\"" atIndex:0];
        [quotedTag appendString:@"\""];

        [quotedTags addObject:quotedTag];
        [quotedTag release];
    }

    NSString * joinedTags = [quotedTags join:@" "];

    NSDictionary * args =
        [NSDictionary dictionaryWithObjectsAndKeys:
        defaultTitle, @"title",
        joinedTags, @"tags",
        nil];

    NSData * imageData = [self dataForImageUsingCompressionSettings:image];
    NSString * mimeType = [self mimeTypeForImage:image];
    NSInputStream * imageStream = [NSInputStream inputStreamWithData:imageData];

    // the next step is slow within the Flickr layer (it copies the image to
    // disk); let the function return so the UI can remain responsive while the
    // video is updated
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
            imageStream, @"stream",
            mimeType, @"mime-type",
            args, @"args",
            nil];

    [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(uploadMedia:)
                                   userInfo:userInfo
                                    repeats:NO];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(FlickrCredentials *)ctls
{
    [super sendVideoAtUrl:url withCredentials:ctls];
    [flickrContext setAuthToken:ctls.token];

    self.uploadRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
    [self.uploadRequest setDelegate:self];

    NSString * defaultTitle =
        NSLocalizedString(@"flickr.video.title.default", @"");
    NSDictionary * args =
        [NSDictionary dictionaryWithObject:defaultTitle forKey:@"title"];

    NSData * videoData = [NSData dataWithContentsOfURL:url];
    NSInputStream * videoStream = [NSInputStream inputStreamWithData:videoData];

    // the next step is slow within the Flickr layer (it copies the image to
    // disk); let the function return so the UI can remain responsive while the
    // video is updated
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
            videoStream, @"stream",
            @"video/quicktime", @"mime-type",
            args, @"args",
            nil];

    [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(uploadMedia:)
                                   userInfo:userInfo
                                    repeats:NO];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)cancelUpload
{
    if (self.uploadRequest)
        [self.uploadRequest cancel];
}

- (void)setTitle:(NSString *)title forPhotoWithUrl:(NSString *)photoUrl
    credentials:(FlickrCredentials *)someCredentials
{
    [super setTitle:title forPhotoWithUrl:photoUrl credentials:someCredentials];
    [self setTitle:title ofMediaAtUrl:photoUrl credentials:someCredentials];

    settingPhotoTitle = YES;
}

- (void)setTitle:(NSString *)title forVideoWithUrl:(NSString *)url
    credentials:(FlickrCredentials *)someCredentials
{
    [super setTitle:title forVideoWithUrl:url credentials:someCredentials];
    [self setTitle:title ofMediaAtUrl:url credentials:someCredentials];

    settingVideoTitle = YES;
}

+ (NSString *)apiKey
{
    return @"922ac08dae0049256158cf822f3760f9";
}

+ (NSString *)sharedSecret
{
    return @"c6252591e93c08e9";
}

#pragma mark OFFlickrAPIRequestDelegate implementation

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
    didCompleteWithResponse:(NSDictionary *)response
{
    if (request == self.uploadRequest) {
        NSString * photoIdString =
            [[response objectForKey:@"photoid"] objectForKey:@"_text"];
        NSNumber * photoId =
            [NSNumber numberWithLongLong:[photoIdString longLongValue]];
        NSString * shortPhotoId = [photoId base58EncodedString];

        NSString * shortUrl =
            [NSString stringWithFormat:@"http://flic.kr/p/%@", shortPhotoId];
        NSLog(@"short url: %@", shortUrl);

        if (self.image)
            [self.delegate service:self didPostImageToUrl:shortUrl];
        else if (self.videoUrl)
            [self.delegate service:self didPostVideoToUrl:shortUrl];

        [uploadRequest autorelease];
        uploadRequest = nil;
    } else if (request == self.editRequest) {
        if (settingPhotoTitle) {
            [self.delegate serviceDidUpdatePhotoTitle:self];
            settingPhotoTitle = NO;
        } else if (settingVideoTitle) {
            [self.delegate serviceDidUpdateVideoTitle:self];
            settingVideoTitle = NO;
        }

        [editRequest autorelease];
        editRequest = nil;
    }

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
        didFailWithError:(NSError *)error
{
    NSLog(@"Request failed: %@", error);

    if (request == self.uploadRequest) {
        if (self.image)
            [self.delegate service:self failedToPostImage:error];
        else if (self.videoUrl)
            [self.delegate service:self failedToPostVideo:error];

        [uploadRequest autorelease];
        uploadRequest = nil;
    } else {
        if (settingPhotoTitle) {
            [self.delegate service:self failedToUpdatePhotoTitle:error];
            settingPhotoTitle = NO;
        } else if (settingVideoTitle) {
            [self.delegate service:self failedToUpdateVideoTitle:error];
            settingVideoTitle = NO;
        }

        [editRequest autorelease];
        editRequest = nil;
    }

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
    imageUploadSentBytes:(NSUInteger)inSentBytes
              totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"Request uploaded %d of %d bytes", inSentBytes, inTotalBytes);
}

#pragma mark Private implementation

- (void)setTitle:(NSString *)title ofMediaAtUrl:(NSString *)url
    credentials:(FlickrCredentials *)someCredentials
{
    [flickrContext setAuthToken:someCredentials.token];

    NSString * shortPhotoId = [[self class] shortPhotoIdFromUrl:url];
    NSString * photoId = [[self class] photoIdFromShortPhotoId:shortPhotoId];

    NSDictionary * args =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
        photoId, @"photo_id",
        title, @"title",
        nil];

    [flickrContext setAuthToken:someCredentials.token];

    self.editRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
    [self.editRequest setDelegate:self];

    [self.editRequest callAPIMethodWithPOST:@"flickr.photos.setMeta"
                                  arguments:args];
}

- (void)uploadMedia:(NSTimer *)timer
{
    NSDictionary * userInfo = timer.userInfo;
    [self.uploadRequest uploadImageStream:[userInfo objectForKey:@"stream"]
                        suggestedFilename:@""
                                 MIMEType:[userInfo objectForKey:@"mime-type"]
                                arguments:[userInfo objectForKey:@"args"]];
}

+ (NSString *)shortPhotoIdFromUrl:(NSString *)urlString
{
    static NSString * regex = @"\\bhttp://flic.kr/p/([a-zA-Z0-9]+)";
    return [urlString stringByMatching:regex capture:1];
}

+ (NSString *)photoIdFromShortPhotoId:(NSString *)shortPhotoId
{
    NSNumber * photoId = [NSNumber numberWithBase58EncodedString:shortPhotoId];
    return [photoId description];
}

@end
