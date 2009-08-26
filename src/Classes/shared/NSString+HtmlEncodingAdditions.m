//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSString+HtmlEncodingAdditions.h"

@implementation NSString (HtmlEncodingAdditions)

- (NSString *)stringByDecodingHtmlEntities
{ 
    NSMutableString * escaped = [NSMutableString stringWithString:self];

    NSArray * entities =
        [NSArray arrayWithObjects:@"&amp;", @"&lt;", @"&gt;", @"&quot;", nil];

    NSArray * characters =
        [NSArray arrayWithObjects:@"&", @"<", @">", @"\"", nil];

    int i, count = [entities count], characterCount = [characters count];

    for(i = 0; i < count; i++) {
        NSRange range = [self rangeOfString:[entities objectAtIndex:i]];
        if(range.location != NSNotFound) {
            if (i < characterCount) {
                [escaped replaceOccurrencesOfString:[entities objectAtIndex:i] 
                                         withString:[characters objectAtIndex:i]
                                            options:NSLiteralSearch 
                                              range:NSMakeRange(0, [escaped length])];
            } else {
                [escaped replaceOccurrencesOfString:[entities objectAtIndex:i] 
                                         withString:[NSString stringWithFormat: @"%C", (160-characterCount) + i] 
                                            options:NSLiteralSearch 
                                              range:NSMakeRange(0, [escaped length])];
            }
        }
    }

    return escaped;    // Note this is autoreleased
}

@end