//
//  OADataFetcher.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 11/5/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "OADataFetcher.h"

@interface OADataFetcher ()

@property (nonatomic, retain) OAMutableURLRequest * request;
@property (nonatomic, retain) NSURLResponse * response;
@property (nonatomic, retain) NSMutableData * responseData;
@property (nonatomic, retain) NSURLConnection * connection;
@property (nonatomic, retain) NSError * error;
@property (nonatomic, assign) id delegate;

@end


@implementation OADataFetcher

@synthesize request, response, responseData, connection, error, delegate;

- (void)dealloc
{
    self.request = nil;
    self.response = nil;
    self.responseData = nil;
    self.connection = nil;
    self.error = nil;
    self.delegate = nil;
    [super dealloc];
}

- (void)fetchDataWithRequest:(OAMutableURLRequest *)aRequest 
					delegate:(id)aDelegate 
		   didFinishSelector:(SEL)finishSelector 
			 didFailSelector:(SEL)failSelector 
{
    self.request = aRequest;
    self.delegate = aDelegate;
    didFinishSelector = finishSelector;
    didFailSelector = failSelector;
    
    [self.request prepare];
    self.responseData = [NSMutableData data];

    self.connection = [NSURLConnection connectionWithRequest:request
                                                    delegate:self];
}

#pragma mark NSURLConnectionDelegate implementation

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    OAServiceTicket *ticket =
        [[OAServiceTicket alloc] initWithRequest:request
                                        response:response
                                      didSucceed:[(NSHTTPURLResponse *)response statusCode] < 400];

    [delegate performSelector:didFinishSelector
                   withObject:ticket
                   withObject:responseData];

    [ticket release];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)err
{
    self.error = err;
    OAServiceTicket * ticket= [[OAServiceTicket alloc] initWithRequest:request
                                                              response:response
                                                            didSucceed:NO];
    [delegate performSelector:didFailSelector
                   withObject:ticket
                   withObject:err];

    [ticket release];
}

@end
