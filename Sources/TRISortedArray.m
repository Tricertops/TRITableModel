//
//  TRISortedArray.m
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

#import "TRISortedArray.h"





#define TRI_PUBLIC_API





#pragma mark -


@interface TRISortedArray ()


@property (readonly) NSMutableArray *backing;

@property (copy) NSComparator combinedComparator;
@property BOOL isAutonomous;
@property (copy) NSSet *observedKeyPaths;


- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;


@end





#pragma mark -


@implementation TRISortedArray





#pragma mark Creating


- (instancetype)initWithCapacity:(NSUInteger)capacity TRI_PUBLIC_API {
    self = [super init];
    if (self) {
        self->_sortDescriptors = [NSArray new];
        self->_backing = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self->_sortDescriptors = [decoder decodeObjectOfClass:[NSArray class] forKey:@"sortDescriptors"];
        [self->_sortDescriptors makeObjectsPerformSelector:@selector(allowEvaluation)];
        
        self->_backing = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:@"objects"];
    }
    return self;
}


/// Used by convenience initializers that already have NSMutableArray instance that can be used directly.
- (instancetype)initWithBacking:(NSMutableArray *)backing {
    self = [self initWithCapacity:0];
    if (self) {
        NSParameterAssert(backing != nil);
        self->_backing = backing;
    }
    return self;
}


- (instancetype)init TRI_PUBLIC_API {
    return [self initWithCapacity:0];
}


- (instancetype)initWithArray:(NSArray *)array sortDescriptor:(NSArray *)sortDescriptors TRI_PUBLIC_API {
    self = [self initWithBacking:[NSMutableArray arrayWithArray:array]];
    if (self) {
        // Sort.
        self.sortDescriptors = sortDescriptors;
    }
    return self;
}


- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithObjects:objects count:count];
    return [self initWithBacking:mutable];
}


//! The following methods already return correct subclass, see tests.
/*
 + (instancetype)array;
 + (instancetype)arrayWithObject:(id)anObject;
 + (instancetype)arrayWithObjects:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
 + (instancetype)arrayWithObjects:(const id [])objects count:(NSUInteger)cnt;
 + (instancetype)arrayWithArray:(NSArray *)array;
 - (instancetype)initWithObjects:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
 - (instancetype)initWithArray:(NSArray *)array;
 - (instancetype)initWithArray:(NSArray *)array copyItems:(BOOL)flag;
 */


+ (instancetype)arrayWithContentsOfFile:(NSString *)path TRI_PUBLIC_API {
    NSMutableArray *mutable = [NSMutableArray arrayWithContentsOfFile:path];
    return [[self alloc] initWithBacking:mutable];
}


+ (instancetype)arrayWithContentsOfURL:(NSURL *)URL TRI_PUBLIC_API {
    NSMutableArray *mutable = [NSMutableArray arrayWithContentsOfURL:URL];
    return [[self alloc] initWithBacking:mutable];
}


- (instancetype)initWithContentsOfFile:(NSString *)path TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithContentsOfFile:path];
    return [self initWithBacking:mutable];
}


- (instancetype)initWithContentsOfURL:(NSURL *)URL TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithContentsOfURL:URL];
    return [self initWithBacking:mutable];
}





#pragma mark -
#pragma mark Querying


- (NSUInteger)count TRI_PUBLIC_API {
    return self.backing.count;
}


- (BOOL)containsObject:(NSObject *)object TRI_PUBLIC_API {
    return [self.backing containsObject:object];
}


- (id)firstObject TRI_PUBLIC_API {
    return self.backing.firstObject;
}


- (id)lastObject TRI_PUBLIC_API {
    return self.backing.lastObject;
}


- (id)objectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    return [self.backing objectAtIndex:index];
}


- (id)objectAtIndexedSubscript:(NSUInteger)index TRI_PUBLIC_API {
    return [self.backing objectAtIndexedSubscript:index];
}


- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    return [self.backing objectsAtIndexes:indexes];
}


- (void)getObjects:(__unsafe_unretained id [])objects range:(NSRange)range TRI_PUBLIC_API {
    [self.backing getObjects:objects range:range];
}


- (NSEnumerator *)objectEnumerator TRI_PUBLIC_API {
    return [self.backing objectEnumerator];
}


- (NSEnumerator *)reverseObjectEnumerator TRI_PUBLIC_API {
    return [self.backing reverseObjectEnumerator];
}





#pragma mark Finding


- (NSUInteger)indexOfObject:(NSObject *)object TRI_PUBLIC_API {
    return [self.backing indexOfObject:object];
}


- (NSUInteger)indexOfObject:(NSObject *)object inRange:(NSRange)range TRI_PUBLIC_API {
    return [self.backing indexOfObject:object inRange:range];
}


- (NSUInteger)indexOfObjectIdenticalTo:(NSObject *)object TRI_PUBLIC_API {
    return [self.backing indexOfObjectIdenticalTo:object];
}


- (NSUInteger)indexOfObjectIdenticalTo:(NSObject *)object inRange:(NSRange)range TRI_PUBLIC_API {
    return [self.backing indexOfObjectIdenticalTo:object inRange:range];
}


- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate TRI_PUBLIC_API {
    return [self.backing indexOfObjectPassingTest:predicate];
}


- (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)options passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate TRI_PUBLIC_API {
    return [self.backing indexOfObjectWithOptions:options passingTest:predicate];
}


- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate TRI_PUBLIC_API {
    return [self.backing indexesOfObjectsPassingTest:predicate];
}


- (NSIndexSet *)indexesOfObjectsWithOptions:(NSEnumerationOptions)options passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate TRI_PUBLIC_API {
    return [self.backing indexesOfObjectsWithOptions:options passingTest:predicate];
}


- (NSIndexSet *)indexesOfObjectsAtIndexes:(NSIndexSet *)indexes options:(NSEnumerationOptions)options passingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate TRI_PUBLIC_API {
    return [self.backing indexesOfObjectsAtIndexes:indexes options:options passingTest:predicate];
}


- (NSUInteger)indexOfObject:(NSObject *)object inSortedRange:(NSRange)range options:(NSBinarySearchingOptions)options usingComparator:(NSComparator)comparator TRI_PUBLIC_API {
    return [self.backing indexOfObject:object inSortedRange:range options:options usingComparator:comparator];
}





#pragma mark Enumerating


- (void)makeObjectsPerformSelector:(SEL)selector TRI_PUBLIC_API {
    [self.backing makeObjectsPerformSelector:selector];
}


- (void)makeObjectsPerformSelector:(SEL)selector withObject:(NSObject *)argument TRI_PUBLIC_API {
    [self.backing makeObjectsPerformSelector:selector withObject:argument];
}


- (void)enumerateObjectsUsingBlock:(void (^)(id, NSUInteger, BOOL *))block TRI_PUBLIC_API {
    [self.backing enumerateObjectsUsingBlock:block];
}


- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(id, NSUInteger, BOOL *))block TRI_PUBLIC_API {
    [self.backing enumerateObjectsWithOptions:options usingBlock:block];
}


- (void)enumerateObjectsAtIndexes:(NSIndexSet *)indexes options:(NSEnumerationOptions)options usingBlock:(void (^)(id, NSUInteger, BOOL *))block TRI_PUBLIC_API {
    [self.backing enumerateObjectsAtIndexes:indexes options:options usingBlock:block];
}





#pragma mark Comparing


- (NSUInteger)hash TRI_PUBLIC_API {
    return self.backing.hash ^ self.sortDescriptors.hash;
}


- (BOOL)isEqualTo:(id)other TRI_PUBLIC_API {
    if (self == other) return YES;
    if ( ! [other isKindOfClass:[NSArray class]]) return NO;
    return [self.backing isEqualToArray:other];
}


- (BOOL)isEqualToArray:(NSArray *)other TRI_PUBLIC_API {
    if (self == other) return YES;
    return [self.backing isEqualToArray:other];
}


- (BOOL)isEqualToSortedArray:(TRISortedArray *)other TRI_PUBLIC_API {
    return ([self isEqualToArray:other]
            && [self.sortDescriptors isEqualToArray:other.sortDescriptors]
            && self.insertsEqualObjectsFirst == other.insertsEqualObjectsFirst);
}


- (id)firstObjectCommonWithArray:(NSArray *)other TRI_PUBLIC_API {
    return [self.backing firstObjectCommonWithArray:other];
}





#pragma mark Deriving


- (NSArray *)copy TRI_PUBLIC_API {
    return [self.backing copy];
}


- (instancetype)mutableCopy TRI_PUBLIC_API {
    TRISortedArray *copy = [[self.class alloc] initWithBacking:[self.backing mutableCopy]];
    copy.sortDescriptors = self.sortDescriptors;
    copy.allowsConcurrentSorting = self.allowsConcurrentSorting;
    copy.insertsEqualObjectsFirst = self.insertsEqualObjectsFirst;
    return copy;
}


- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)other TRI_PUBLIC_API {
    return [self.backing arrayByAddingObjectsFromArray:other];
}


- (NSArray *)subarrayFromIndex:(NSUInteger)firstIncludedIndex TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    NSParameterAssert(firstIncludedIndex < backing.count);
    NSUInteger count = backing.count - firstIncludedIndex;
    return [backing subarrayWithRange:NSMakeRange(firstIncludedIndex, count)];
}


- (NSArray *)subarrayToIndex:(NSUInteger)firstNotIncludedIndex TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    NSParameterAssert(firstNotIncludedIndex <= backing.count);
    return [backing subarrayWithRange:NSMakeRange(0, firstNotIncludedIndex)];
}


- (NSArray *)subarrayWithRange:(NSRange)range TRI_PUBLIC_API {
    return [self subarrayWithRange:range];
}





#pragma mark -
#pragma mark Adding


- (void)addObject:(NSObject *)object TRI_PUBLIC_API {
    NSUInteger index = [self proposedIndexOfObject:object];
    [self.backing insertObject:object atIndex:index];
}


- (void)addObjectsFromCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    if ([collection isKindOfClass:[NSArray class]]) {
        NSIndexSet *indexes = [self proposedIndexesOfObjectsInCollection:collection];
        [backing insertObjects:(NSArray *)collection atIndexes:indexes];
    }
    else {
        for (NSObject *object in collection) {
            NSUInteger index = [self proposedIndexOfObject:object];
            [backing insertObject:object atIndex:index];
        }
    }
}


- (NSUInteger)proposedIndexOfObject:(NSObject *)object TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    NSComparator comparator = self.combinedComparator;
    if (comparator) {
        NSRange range = NSMakeRange(0, backing.count);
        NSBinarySearchingOptions options = NSBinarySearchingInsertionIndex;
        options |= (self.insertsEqualObjectsFirst
                    ? NSBinarySearchingFirstEqual
                    : NSBinarySearchingLastEqual);
        return [backing indexOfObject:object inSortedRange:range options:options usingComparator:comparator];
    }
    else {
        return backing.count;
    }
}


- (NSIndexSet *)proposedIndexesOfObjectsInCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    // These indexes are good only for inserting those object one after another.
    NSMutableIndexSet *independentIdexes = [NSMutableIndexSet new];
    for (NSObject *object in collection) {
        NSUInteger index = [self proposedIndexOfObject:object];
        [independentIdexes addIndex:index];
    }
    // These indexes are shifted by previous inserts, so these can then be used for adding multiple objects at once.
    NSMutableIndexSet *shiftedIndexes = [NSMutableIndexSet new];
    __block NSUInteger shift = 0;
    [independentIdexes enumerateIndexesUsingBlock:^(NSUInteger index, __unused BOOL *stop) {
        [shiftedIndexes addIndex:(index + shift)];
        shift ++;
    }];
    return shiftedIndexes;
}





#pragma mark Removing


- (void)removeAllObjects TRI_PUBLIC_API {
    [self.backing removeAllObjects];
}


- (void)removeObject:(NSObject *)object TRI_PUBLIC_API {
    [self.backing removeObject:object];
}


- (void)removeObjectIdenticalTo:(NSObject *)object TRI_PUBLIC_API {
    [self.backing removeObjectIdenticalTo:object];
}


- (void)removeObjectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    [self.backing removeObjectAtIndex:index];
}


- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    [self.backing removeObjectsAtIndexes:indexes];
}

- (void)removeObjectsInRange:(NSRange)range TRI_PUBLIC_API {
    [self.backing removeObjectsInRange:range];
}


- (void)removeObjectsInCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    if ([collection isKindOfClass:[NSArray class]]) {
        [backing removeObjectsInArray:(NSArray *)collection];
    }
    else {
        for (NSObject *object in collection) {
            [backing removeObject:object];
        }
    }
}





#pragma mark Filtering


- (void)filterUsingPredicate:(NSPredicate *)predicate TRI_PUBLIC_API {
    [self.backing filterUsingPredicate:predicate];
}


- (void)filterUsingBlock:(BOOL (^)(id, NSUInteger))shouldKeep TRI_PUBLIC_API {
    NSUInteger index = 0;
    NSMutableArray *backing = self.backing;
    for (NSObject *object in [backing copy]) {
        if ( ! shouldKeep(object, index)) {
            [backing removeObjectAtIndex:index];
        }
        index ++;
    }
}


- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate TRI_PUBLIC_API {
    return [self.backing filteredArrayUsingPredicate:predicate];
}





#pragma mark -
#pragma mark Sorting


@synthesize sortDescriptors = _sortDescriptors;


- (NSArray *)sortDescriptors TRI_PUBLIC_API {
    if ( ! self->_sortDescriptors) {
        self->_sortDescriptors = @[];
    }
    return self->_sortDescriptors;
}


- (void)setSortDescriptors:(NSArray *)sortDescriptors TRI_PUBLIC_API {
    sortDescriptors = [sortDescriptors copy];
    self->_sortDescriptors = sortDescriptors;
    
    if (sortDescriptors.count > 0) {
        NSUInteger missingKeyPaths = NSUIntegerMax;
        NSSet *keyPaths = [self keyPathsFromSortDescriptors:sortDescriptors countMissing:&missingKeyPaths];
        self.isAutonomous = (missingKeyPaths == 0);
        if ( ! self.isAutonomous) {
            NSLog(@"<%@ %p> is NOT autonomous and cannot fully resort itself based on KVO, use NSSortDescriptors with defined `key` to allow autonomous resorting.", self.class, self);
        }
        self.observedKeyPaths = keyPaths;
        //TODO: Observe key-paths
        
        [self setCombinedComparator:^NSComparisonResult(id objectA, id objectB) {
            for (NSSortDescriptor *descriptor in sortDescriptors) {
                NSComparisonResult result = [descriptor compareObject:objectA toObject:objectB];
                if (result != NSOrderedSame)
                    return result;
            }
            return NSOrderedSame;
        }];
        [self sortAllObjects];
    }
    else {
        self.combinedComparator = nil;
        self.isAutonomous = NO;
        self.observedKeyPaths = nil;
        //TODO: Un-observe key-paths
    }
}


- (NSSet *)keyPathsFromSortDescriptors:(NSArray *)sortDescriptors countMissing:(out NSUInteger *)missingCountRef {
    NSMutableSet *keyPaths = [NSMutableSet setWithCapacity:sortDescriptors.count];
    NSUInteger missing = 0;
    for (NSSortDescriptor *descriptor in sortDescriptors) {
        if (descriptor.key) {
            [keyPaths addObject:descriptor.key];
        }
        else {
            missing ++;
        }
    }
    if (missingCountRef) {
        *missingCountRef = missing;
    }
    return keyPaths;
}


- (void)sortAllObjects TRI_PUBLIC_API {
    NSComparator comparator = self.combinedComparator;
    if (comparator) {
        NSSortOptions options = NSSortStable;
        if (self.allowsConcurrentSorting) {
            options |= NSSortConcurrent;
        }
        [self.backing sortWithOptions:options usingComparator:comparator];
    }
}


- (void)sortObject:(NSObject *)object TRI_PUBLIC_API {
    if ([self.backing containsObject:object]) {
        [self removeObject:object];
        [self addObject:object];
    }
}


- (void)sortObjectIdenticalTo:(id)object TRI_PUBLIC_API {
    if ([self.backing indexOfObjectIdenticalTo:object] != NSNotFound) {
        [self removeObjectIdenticalTo:object];
        [self addObject:object];
    }
}


- (void)sortObjectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    id object = [self.backing objectAtIndex:index];
    [self removeObjectAtIndex:index];
    [self addObject:object];
}


- (void)sortObjectAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    NSArray *objects = [self.backing objectsAtIndexes:indexes];
    [self removeObjectsAtIndexes:indexes];
    [self addObjectsFromCollection:objects];
}


- (void)sortObjectsInRange:(NSRange)range TRI_PUBLIC_API {
    NSArray *objects = [self.backing subarrayWithRange:range];
    [self removeObjectsInRange:range];
    [self addObjectsFromCollection:objects];
}


- (void)sortObjectsInCollection:(id<NSFastEnumeration>)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    // Find only those that are actually contained.
    NSMutableArray *subcollection = [NSMutableArray new];
    for (NSObject *object in collection) {
        if ([backing containsObject:object]) {
            [subcollection addObject:object];
        }
    }
    [self removeObjectsInCollection:subcollection];
    [self addObjectsFromCollection:subcollection];
}




























@end


