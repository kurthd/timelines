//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTimelineResponseProcessor.h"

@interface FetchTimelineResponseProcessor ()

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTimelineResponseProcessor

@synthesize updateId, page, count, delegate;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                              count:aCount
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.updateId = nil;
    self.page = nil;
    self.count = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.updateId = anUpdateId;
        self.page = aPage;
        self.count = aCount;
        self.delegate = aDelegate;
    }

    return self;
}

- (void)processResponse:(NSArray *)statuses
{
    if (statuses) {
        SEL sel = @selector(timeline:fetchedSinceUpdateId:page:count:);
        [self invokeSelector:sel withTarget:delegate args:statuses, updateId,
            page, count, nil];
    }
}

- (void)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchTimelineSinceUpdateId:page:count:error:);
    [self invokeSelector:sel withTarget:delegate args:updateId, page, count,
        error, nil];
}

@end
