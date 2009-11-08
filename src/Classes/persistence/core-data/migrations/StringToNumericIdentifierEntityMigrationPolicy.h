//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StringToNumericIdentifierEntityMigrationPolicy :
    NSEntityMigrationPolicy
{
    NSMutableSet * attributesToMigrate;
}

@end
