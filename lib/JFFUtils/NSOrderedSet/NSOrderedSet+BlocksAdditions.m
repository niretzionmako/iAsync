#import "NSOrderedSet+BlocksAdditions.h"

@implementation NSMutableOrderedSet (BlocksAdditions)

+ (instancetype)converToCurrentTypeMutableOrderedSet:(NSMutableOrderedSet *)set
{
    return set;
}

@end

@implementation NSOrderedSet (BlocksAdditions)

+ (instancetype)converToCurrentTypeMutableOrderedSet:(NSMutableOrderedSet *)set
{
    return [set copy];
}

+ (instancetype)setWithSize:(NSUInteger)size
                   producer:(JFFProducerBlock)block
{
    NSMutableOrderedSet *result = [[NSMutableOrderedSet alloc] initWithCapacity:size];
    
    for (NSUInteger index = 0; index < size; ++index) {
        [result addObject:block(index)];
    }
    
    return [self converToCurrentTypeMutableOrderedSet:result];
}

//TODO test
//TODO remove code duplicate
- (instancetype)map:(JFFMappingBlock)block
{
    NSMutableOrderedSet *result = [[NSMutableOrderedSet alloc] initWithCapacity:[self count]];
    
    for (id object in self) {
        id newObject = block(object);
        NSParameterAssert(newObject);
        [result addObject:newObject];
    }
    
    return [result copy];
}

- (instancetype)forceMap:(JFFMappingBlock)block
{
    NSMutableOrderedSet *result = [[NSMutableOrderedSet alloc] initWithCapacity:[self count]];
    
    for (id object in self) {
        id newObject = block(object);
        if (newObject) {
            [result addObject:newObject];
        }
    }
    
    return [result copy];
}

- (id)firstMatch:(JFFPredicateBlock)predicate
{
    for (id object in self) {
        if (predicate(object))
            return object;
    }
    return nil;
}

- (BOOL)any:(JFFPredicateBlock)predicate
{
    id object = [self firstMatch:predicate];
    return object != nil;
}

- (BOOL)all:(JFFPredicateBlock)predicate
{
    JFFPredicateBlock notPredicate = ^BOOL(id object) {
        return !predicate(object);
    };
    return ![self any:notPredicate];
}

- (instancetype)select:(JFFPredicateBlock)predicate
{
    NSIndexSet *indexes = [self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        return predicate(obj);
    }];
    return [[NSOrderedSet alloc] initWithArray:[self objectsAtIndexes:indexes]];
}

@end
