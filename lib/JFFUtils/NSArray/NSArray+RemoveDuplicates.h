#import <JFFUtils/Blocks/JUContainersHelperBlocks.h>
#import <Foundation/Foundation.h>

@interface NSArray( RemoveDuplicates )

- (NSArray *)arrayByRemovingDuplicates; //uses @selector(isEual:)
- (NSArray *)arrayByRemovingDuplicatesUsingIsEqualBlock:(JFFEqualityCheckerBlock)predicate;

//Same methods using functional programming notation
- (NSArray *)unique; //uses @selector(isEual:)
- (NSArray *)uniqueBy:(JFFEqualityCheckerBlock)predicate;

@end
