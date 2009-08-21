/****************************************************************************
 TwitVid.h
 
 Defines interface to libTwitVid.a, iPhone library to access TwitVid server
 and post videos
 
 Please refer to the developer section of the TwitVid site for further details
 
 libTwitVid.a is a universal binary containing both arm and i386 builds of the
 library so that it can be used for both device and simulator builds.
 ****************************************************************************/
#import <Foundation/Foundation.h>

@protocol TwitVidRequestInterface;
@protocol TwitVidDelegate;

typedef NSObject<TwitVidRequestInterface> TwitVidRequest;

@interface TwitVid : NSObject
{
@private
	NSString            *username;
	NSString            *password;
    NSString            *token;
    NSDate              *tokenExpires;
	id<TwitVidDelegate>  delegate;
	NSTimeInterval       timeout;
}


/****************************************************************************
 + (float)durationOfMovieFile:(NSString*)path
 
 Returns the length in seconds of the movie contained in the file specified 
 
 Returns length or zero 
 ****************************************************************************/
+ (float)durationOfMovieFile:(NSString*)path;


/****************************************************************************
 + (float)durationOfMovieURLFile:(NSURL*)path
 
 Returns the length in seconds of the movie contained in the url specified 
 
 Returns length or zero 
 ****************************************************************************/
+ (float)durationOfMovieURLFile:(NSURL*)path;


/****************************************************************************
+ (TwitVid*)twitVidWithUsername:(NSString*)aUsername
                       password:(NSString*)aPassword
                       delegate:(id<TwitVidDelegate>)aDelegate
 
 Returns an instance of TwitVid initialized with the given account
 credentials and delegate.
 
 The delegate will receive progress notifications for all requests created
 with the instance.
 
 Returns initialized instance or Nil if error
 ****************************************************************************/
+ (TwitVid*)twitVidWithUsername:(NSString*)aUsername
                       password:(NSString*)aPassword
                       delegate:(id<TwitVidDelegate>)aDelegate;


/****************************************************************************
- (id)initWithUsername:(NSString*)aUsername
              password:(NSString*)aPassword
              delegate:(id<TwitVidDelegate>)aDelegate

 Initialize an instance of TwitVid for the given account credentials and 
 delegate.
 
 The delegate will receive progress notifications for all requests created
 with the instance.
 
 Returns initialized instance or Nil if error
****************************************************************************/
- (id)initWithUsername:(NSString *)aUsername 
              password:(NSString *)aPassword 
              delegate:(id<TwitVidDelegate>)aDelegate;


/****************************************************************************
 - (TwitVidRequest*)authenticate
 
 Authenticate against TwitVid server over https and save resulting token in 
 the TwitVid instance. Once this method has successfully been called all 
 other methods will use token rather than username and password.
 
 Tokens expire after (at time of writing) 360 minutes. See tokenValid to
 check if authenticate needed to be called again if instance of TwitVid is
 kept instantiated permanently in app.
 
 The delegate will receive progress notifications of progress during the 
 authenticate exchange.
 
 The tokenValid property should be checked to see if a authentication is
 required as the authentication token is stored persistently and authentication
 is only required if tokenValid is false. There is a limit to the number of
 Twitter authentications per hour so it is advised to implement this check.
 
 IT IS STRONGLY RECOMMEND THAT THIS METHOD OF AUTHENTICATION IS USED INSTEAD
 OF USING USERNAME / PASSWORD WITH EACH CALL. USERNAME / PASSWORD IS THE 
 DEFAULT BEHAVIOR IF A SUCCESSFUL authenticate CALL HAS NOT BEEN MADE PRIOR 
 TO USING ANY OF THE OTHER TwitVid METHODS. IF USERNAME / PASSWORD ARE SENT 
 WITH THESE METHODS THEY ARE IN CLEAR TEXT. AUTHENTICATE IS THE ONLY METHOD
 THAT USES HTTPS.
 
 Returns initialized instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)authenticate;


/****************************************************************************
 - (void)logout

 Deletes saved token so that authentication required again to obtain new
 token
 ****************************************************************************/
- (void)logout;


/****************************************************************************
- (TwitVidRequest*)uploadWithMediaFileAtPath:(NSString *)filePath 
                                     message:(NSString *)message
                                  playlistId:(NSString *)playlistId 
                           vidResponseParent:(NSString *)vidResponseParent 
                             youtubeUsername:(NSString *)youtubeUsername 
                             youtubePassword:(NSString *)youtubePassword 
                                    userTags:(NSString *)userTags 
                                 geoLatitude:(NSString *)geoLatitude 
                                geoLongitude:(NSString *)geoLongitude
                                 posterImage:(NSString *)posterImage
                                      source:(NSString *)source
                                    realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site, for details on arguments
 see http://twitvid.pbworks.com
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading
 
 Set any unrequired parameters to Nil, filePath and message are required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadWithMediaFileAtPath:(NSString *)filePath
                                     message:(NSString* )message
                                  playlistId:(NSString *)playlistId 
                           vidResponseParent:(NSString *)vidResponseParent 
                             youtubeUsername:(NSString *)youtubeUsername 
                             youtubePassword:(NSString *)youtubePassword 
                                    userTags:(NSString *)userTags 
                                 geoLatitude:(NSString *)geoLatitude 
                                geoLongitude:(NSString *)geoLongitude
                                 posterImage:(NSString *)posterImage
                                      source:(NSString *)source
                                    realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadWithMediaFileAtURL:(NSURL *)fileURL 
                                     message:(NSString *)message
                                  playlistId:(NSString *)playlistId 
                           vidResponseParent:(NSString *)vidResponseParent 
                             youtubeUsername:(NSString *)youtubeUsername 
                             youtubePassword:(NSString *)youtubePassword 
                                    userTags:(NSString *)userTags 
                                 geoLatitude:(NSString *)geoLatitude 
                                geoLongitude:(NSString *)geoLongitude
                                 posterImage:(NSString *)posterImage
                                      source:(NSString *)source
                                    realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site, for details on arguments
 see http://twitvid.pbworks.com
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading
 
 Set any unrequired parameters to Nil, filePath and message are required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadWithMediaFileAtURL:(NSURL *)fileURL
                                    message:(NSString* )message
                                 playlistId:(NSString *)playlistId 
                          vidResponseParent:(NSString *)vidResponseParent 
                            youtubeUsername:(NSString *)youtubeUsername 
                            youtubePassword:(NSString *)youtubePassword 
                                   userTags:(NSString *)userTags 
                                geoLatitude:(NSString *)geoLatitude 
                               geoLongitude:(NSString *)geoLongitude
                                posterImage:(NSString *)posterImage
                                     source:(NSString *)source
                                   realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadAndPostWithMediaFileAtPath:(NSString *)filePath 
                                             message:(NSString *)message
                                          playlistId:(NSString *)playlistId 
                                   vidResponseParent:(NSString *)vidResponseParent 
                                     youtubeUsername:(NSString *)youtubeUsername 
                                     youtubePassword:(NSString *)youtubePassword 
                                            userTags:(NSString *)userTags 
                                         geoLatitude:(NSString *)geoLatitude 
                                        geoLongitude:(NSString *)geoLongitude
                                         posterImage:(NSString *)posterImage
                                              source:(NSString *)source
                                            realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site and send a tweet to twitter, 
 for details on arguments see http://twitvid.pbworks.com
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading

 Set any unrequired parameters to Nil, filePath is required.

 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadAndPostWithMediaFileAtPath:(NSString *)filePath 
                                            message:(NSString *)message 
                                         playlistId:(NSString *)playlistId 
                                  vidResponseParent:(NSString *)vidResponseParent 
                                    youtubeUsername:(NSString *)youtubeUsername 
                                    youtubePassword:(NSString *)youtubePassword 
                                           userTags:(NSString *)userTags 
                                        geoLatitude:(NSString *)geoLatitude 
                                       geoLongitude:(NSString *)geoLongitude
                                        posterImage:(NSString *)posterImage
                                             source:(NSString *)source
                                           realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadAndPostWithMediaFileAtURL:(NSURL *)fileURL 
                                            message:(NSString *)message
                                         playlistId:(NSString *)playlistId 
                                  vidResponseParent:(NSString *)vidResponseParent 
                                    youtubeUsername:(NSString *)youtubeUsername 
                                    youtubePassword:(NSString *)youtubePassword 
                                           userTags:(NSString *)userTags 
                                        geoLatitude:(NSString *)geoLatitude 
                                       geoLongitude:(NSString *)geoLongitude
                                        posterImage:(NSString *)posterImage
                                             source:(NSString *)source
                                           realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site and send a tweet to twitter, 
 for details on arguments see http://twitvid.pbworks.com
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading
 
 Set any unrequired parameters to Nil, filePath is required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadAndPostWithMediaFileAtURL:(NSURL *)fileURL 
                                           message:(NSString *)message 
                                        playlistId:(NSString *)playlistId 
                                 vidResponseParent:(NSString *)vidResponseParent 
                                   youtubeUsername:(NSString *)youtubeUsername 
                                   youtubePassword:(NSString *)youtubePassword 
                                          userTags:(NSString *)userTags 
                                       geoLatitude:(NSString *)geoLatitude 
                                      geoLongitude:(NSString *)geoLongitude
                                       posterImage:(NSString *)posterImage
                                            source:(NSString *)source
                                          realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadOrResumeWithMediaFileAtPath:(NSString *)filePath 
                                               offset:(uint64_t)offset
                                              message:(NSString *)message
                                           playlistId:(NSString *)playlistId 
                                    vidResponseParent:(NSString *)vidResponseParent 
                                      youtubeUsername:(NSString *)youtubeUsername 
                                      youtubePassword:(NSString *)youtubePassword 
                                             userTags:(NSString *)userTags 
                                          geoLatitude:(NSString *)geoLatitude 
                                         geoLongitude:(NSString *)geoLongitude
                                          posterImage:(NSString *)posterImage
                                               source:(NSString *)source
                                             realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site, for details on arguments 
 see http://twitvid.pbworks.com with support for resuming upload from given 
 file offset
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading

 Set any unrequired parameters to Nil, filePath, mediaId and message are
 required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadOrResumeWithMediaFileAtPath:(NSString *)filePath 
                                              offset:(uint64_t)offset 
                                             mediaId:(NSString *)mediaId 
                                             message:(NSString *)message
                                          playlistId:(NSString *)playlistId 
                                   vidResponseParent:(NSString *)vidResponseParent 
                                     youtubeUsername:(NSString *)youtubeUsername 
                                     youtubePassword:(NSString *)youtubePassword 
                                            userTags:(NSString *)userTags 
                                         geoLatitude:(NSString *)geoLatitude 
                                        geoLongitude:(NSString *)geoLongitude
                                         posterImage:(NSString *)posterImage
                                              source:(NSString *)source
                                            realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadOrResumeWithMediaFileAtURL:(NSURL *)fileURL 
                                              offset:(uint64_t)offset
                                             message:(NSString *)message
                                          playlistId:(NSString *)playlistId 
                                   vidResponseParent:(NSString *)vidResponseParent 
                                     youtubeUsername:(NSString *)youtubeUsername 
                                     youtubePassword:(NSString *)youtubePassword 
                                            userTags:(NSString *)userTags 
                                         geoLatitude:(NSString *)geoLatitude 
                                        geoLongitude:(NSString *)geoLongitude
                                         posterImage:(NSString *)posterImage
                                              source:(NSString *)source
                                            realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site, for details on arguments 
 see http://twitvid.pbworks.com with support for resuming upload from given 
 file offset
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading
 
 Set any unrequired parameters to Nil, filePath, mediaId and message are
 required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadOrResumeWithMediaFileAtURL:(NSURL *)fileURL 
                                             offset:(uint64_t)offset 
                                            mediaId:(NSString *)mediaId 
                                            message:(NSString *)message
                                         playlistId:(NSString *)playlistId 
                                  vidResponseParent:(NSString *)vidResponseParent 
                                    youtubeUsername:(NSString *)youtubeUsername 
                                    youtubePassword:(NSString *)youtubePassword 
                                           userTags:(NSString *)userTags 
                                        geoLatitude:(NSString *)geoLatitude 
                                       geoLongitude:(NSString *)geoLongitude
                                        posterImage:(NSString *)posterImage
                                             source:(NSString *)source
                                           realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadOrResumeAndPostWithMediaFileAtPath:(NSString *)filePath 
                                                      offset:(uint64_t)offset
                                                     message:(NSString *)message
                                                  playlistId:(NSString *)playlistId 
                                           vidResponseParent:(NSString *)vidResponseParent 
                                             youtubeUsername:(NSString *)youtubeUsername 
                                             youtubePassword:(NSString *)youtubePassword 
                                                    userTags:(NSString *)userTags 
                                                 geoLatitude:(NSString *)geoLatitude 
                                                geoLongitude:(NSString *)geoLongitude
                                                 posterImage:(NSString *)posterImage
                                                      source:(NSString *)source
                                                    realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site and send a tweet to twitter, 
 for details on arguments see http://twitvid.pbworks.com with support for
 resuming upload from given file offset
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading

 Set any unrequired parameters to Nil, filePath and mediaId are required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadOrResumeAndPostWithMediaFileAtPath:(NSString *)filePath 
                                                     offset:(uint64_t)offset 
                                                    mediaId:(NSString *)mediaId 
                                                    message:(NSString *)message 
                                                 playlistId:(NSString *)playlistId 
                                          vidResponseParent:(NSString *)vidResponseParent 
                                            youtubeUsername:(NSString *)youtubeUsername 
                                            youtubePassword:(NSString *)youtubePassword 
                                                   userTags:(NSString *)userTags 
                                                geoLatitude:(NSString *)geoLatitude 
                                               geoLongitude:(NSString *)geoLongitude
                                                posterImage:(NSString *)posterImage
                                                     source:(NSString *)source
                                                   realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)uploadOrResumeAndPostWithMediaFileAtURL:(NSURL *)fileURL 
                                                     offset:(uint64_t)offset
                                                    message:(NSString *)message
                                                 playlistId:(NSString *)playlistId 
                                          vidResponseParent:(NSString *)vidResponseParent 
                                            youtubeUsername:(NSString *)youtubeUsername 
                                            youtubePassword:(NSString *)youtubePassword 
                                                   userTags:(NSString *)userTags 
                                                geoLatitude:(NSString *)geoLatitude 
                                               geoLongitude:(NSString *)geoLongitude
                                                posterImage:(NSString *)posterImage
                                                     source:(NSString *)source
                                                   realtime:(BOOL)realtime
 
 Initiate an upload of a media file to TwitVid site and send a tweet to twitter, 
 for details on arguments see http://twitvid.pbworks.com with support for
 resuming upload from given file offset
 
 If realtime is TRUE the file is preprocessed for quicktime fast loading
 
 Set any unrequired parameters to Nil, filePath and mediaId are required.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)uploadOrResumeAndPostWithMediaFileAtURL:(NSURL *)fileURL 
                                                    offset:(uint64_t)offset 
                                                   mediaId:(NSString *)mediaId 
                                                   message:(NSString *)message 
                                                playlistId:(NSString *)playlistId 
                                         vidResponseParent:(NSString *)vidResponseParent 
                                           youtubeUsername:(NSString *)youtubeUsername 
                                           youtubePassword:(NSString *)youtubePassword 
                                                  userTags:(NSString *)userTags 
                                               geoLatitude:(NSString *)geoLatitude 
                                              geoLongitude:(NSString *)geoLongitude
                                               posterImage:(NSString *)posterImage
                                                    source:(NSString *)source
                                                  realtime:(BOOL)realtime;


/****************************************************************************
 - (TwitVidRequest*)getId
 
 Initiate a request for a new media id
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)getId;


/****************************************************************************
 - (TwitVidRequest*)getId
 
 Initiate a request for the last byte received by the TwitVid server for the
 specified media id
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)getLastByteWithMediaId:(NSString *)mediaId;


/****************************************************************************
 - (TwitVidRequest*)createPlaylistWithName:(NSString *)playlistName
 
 Initiate a request to create a playlist, optionally with a name. If the
 playlist is not to be named pass Nil.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)createPlaylistWithName:(NSString *)playlistName;


/****************************************************************************
 - (TwitVidRequest*)getVideosWithSource:(NSString *)source
                                   page:(NSString*)page
                               pageSize:(NSString*)pageSize
                                orderBy:(NSString*)orderBy
 
 Initiate a request to get a list of your uploaded videos. All arguments are
 optional, see http://twitvid.pbworks.com for details.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)getVideosWithSource:(NSString *)source 
                                  page:(NSString *)page 
                              pageSize:(NSString *)pageSize 
                               orderBy:(NSString *)orderBy;

/****************************************************************************
 - (TwitVidRequest*)getVideoTopVideosForPage:(NSString*)page
                                    pageSize:(NSString*)pageSize
 
 Initiate a request to get a list of current top videos. All arguments are
 optional, see http://twitvid.pbworks.com for details.
 
 The delegate will receive progress notifications of progress during the upload
 
 Returns TwitVidRequest instance or Nil if error
 ****************************************************************************/
- (TwitVidRequest*)getTopVideosForPage:(NSString*)page
                              pageSize:(NSString*)pageSize;

/****************************************************************************
 Username and password can be read through properties 
 ****************************************************************************/
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;

/****************************************************************************
 Token can be read if successful authentication call has occured 
 ****************************************************************************/
@property (nonatomic, readonly) NSString *token;

/****************************************************************************
 Returns true if token has been obtained using authenticate method and its
 not expired
 ****************************************************************************/
@property (nonatomic, readonly) BOOL tokenValid;

/****************************************************************************
 Delegate and timeout can be read or changed through property
 ****************************************************************************/
@property (nonatomic, assign) id<TwitVidDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval timeout;

@end



/****************************************************************************
 The TwitVidRequest objects returned when a call is started and passed
 to the delegate implements the TwitVidRequestInterface protocol. Use this 
 protocol to obtain details about the request whilst handling a delegate call.
 ****************************************************************************/
@protocol TwitVidRequestInterface

/****************************************************************************
 Timeout can be read or changed through property, it will be initialized to
 the timeout value set in the TwitVid instance that created the request but
 can subsequently be changed
 ****************************************************************************/
@property (nonatomic, assign) NSTimeInterval timeout;

/****************************************************************************
 When request completes a dictionary will be available containing the contents
 of the response message returned by the TwitVid server. See
 http://twitvid.pbworks.com for details of each request calls response data.
 ****************************************************************************/
@property (nonatomic, readonly) NSDictionary *response;

/****************************************************************************
 callName contains the name of the call made and can be used to identify 
 what kind of request the delegate method was called for.
 ****************************************************************************/
@property (nonatomic, readonly) NSString *callName;

/****************************************************************************
 The following four properties give details of the progress 
 ****************************************************************************/
@property (nonatomic, readonly) uint64_t bytesSent;
@property (nonatomic, readonly) uint64_t bytesReceived;
@property (nonatomic, readonly) uint64_t bytesExpectedToSend;
@property (nonatomic, readonly) uint64_t bytesExpectedToReceive;

/****************************************************************************
 stop will stop the request
 ****************************************************************************/
- (void)stop;

@end


/****************************************************************************
 The delegate passed when creating instances of TwitVid should implement the
 TwitVidDelegate protocol
 ****************************************************************************/
@protocol TwitVidDelegate

/****************************************************************************
- (void)request:(TwitVidRequest*)request didFailWithError:(NSError *)error
 
 Will be called when an error occurs during the call. 
 ****************************************************************************/
@optional
- (void)request:(TwitVidRequest*)request 
didFailWithError:(NSError *)error;

/****************************************************************************
 - (void)request:(TwitVidRequest*)request didFailWithError:(NSError *)error
 
 Will be called when a response from TwitVid server has been successfully
 received. When this delegate method is been called the 'response' dictionary
 of the TwitVidRequest will be valid. It will always contain a 'status' key 
 with value either 'ok' or 'fail'. If status is 'fail' then key 'error' 
 with NSError object is included.
 
 If status is 'ok' the dictionary contains the TwitVid server response parsed 
 into key-value pairs. All values are either strings, arrays or dictionaries.
 ****************************************************************************/
@optional
- (void)request:(TwitVidRequest*)request 
didReceiveResponse:(NSDictionary *)response;

/****************************************************************************
 - (void)request:(TwitVidRequest*)request 
    didSendBytes:(uint64_t)bytesSent 
   totalExpected:(uint64_t)expectedBytes;
 
 Will be called to feedback progress during the POST phase of the call 
 ****************************************************************************/
@optional
- (void)request:(TwitVidRequest*)request 
   didSendBytes:(uint64_t)bytesSent 
  totalExpected:(uint64_t)expectedBytes;

/****************************************************************************
 - (void)request:(TwitVidRequest*)request 
 didReceiveBytes:(uint64_t)bytesReceived 
   totalExpected:(uint64_t)expectedBytes;
 
 Will be called to feedback progress during the receipt of the TwitVid server
 response to the call 
 ****************************************************************************/
@optional
- (void)request:(TwitVidRequest*)request 
didReceiveBytes:(uint64_t)bytesReceived 
  totalExpected:(uint64_t)expectedBytes;

@end

