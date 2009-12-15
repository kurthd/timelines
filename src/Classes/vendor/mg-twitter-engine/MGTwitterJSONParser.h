//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngineGlobalHeader.h"
#import "MGTwitterParserDelegate.h"
#import "MGTwitterEngineDelegate.h"

@interface MGTwitterJSONParser : NSObject
{
    __weak NSObject <MGTwitterParserDelegate> * delegate; // weak ref
    NSString * identifier;
    MGTwitterRequestType requestType;
    MGTwitterResponseType responseType;
    NSURL * URL;
}

+ (id)parserWithJSON:(NSData *)theJSON
            delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)identifier
         requestType:(MGTwitterRequestType)reqType
        responseType:(MGTwitterResponseType)respType
                 URL:(NSURL *)URL;
- (id)initWithJSON:(NSData *)theJSON
          delegate:(NSObject *)theDelegate 
    connectionIdentifier:(NSString *)identifier
             requestType:(MGTwitterRequestType)reqType 
            responseType:(MGTwitterResponseType)respType
                     URL:(NSURL *)URL;

@end
