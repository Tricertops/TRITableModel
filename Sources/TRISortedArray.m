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
@property (copy) NSSet *observedKeyPaths;

@property (readonly) NSHashTable *observers;
@property (readonly) NSMapTable *subscriptions;
@property NSInteger mutations;


- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;


@end





#pragma mark -


@implementation TRISortedArray





#pragma mark Initializing


- (instancetype)initWithCapacity:(NSUInteger)capacity TRI_PUBLIC_API {
    self = [super init];
    if (self) {
        self->_backing = [NSMutableArray arrayWithCapacity:capacity];
        self->_sortDescriptors = [NSArray new];
        self->_observers = [NSHashTable weakObjectsHashTable];
        self->_subscriptions = [NSMapTable weakToStrongObjectsMapTable];
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
        self->_sortDescriptors = sortDescriptors;
        [self updateSortingAttributes];
    }
    return self;
}


- (TRISortedArray *)sortedCopy {
    TRISortedArray *copy = [[self.class alloc] initWithBacking:[self.backing mutableCopy]];
    copy.sortDescriptors = self.sortDescriptors;
    copy.isReversed = self.isReversed;
    copy.allowsConcurrentSorting = self.allowsConcurrentSorting;
    copy.insertsEqualObjectsFirst = self.insertsEqualObjectsFirst;
    return copy;
}





#pragma mark Coding


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self->_backing = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:@"TRI.objects"] ?: [NSMutableArray new];
        
        self->_sortDescriptors = [decoder decodeObjectOfClass:[NSArray class] forKey:@"TRI.sortDescriptors"];
        self->_isReversed = [decoder decodeBoolForKey:@"TRI.isReversed"];
        self->_allowsConcurrentSorting = [decoder decodeBoolForKey:@"TRI.allowsConcurrent"];
        self->_insertsEqualObjectsFirst = [decoder decodeBoolForKey:@"TRI.equalFirst"];
        
        self->_observers = [decoder decodeObjectOfClass:[NSHashTable class] forKey:@"TRI.observers"] ?: [NSHashTable weakObjectsHashTable];
        self->_subscriptions = [NSMapTable weakToStrongObjectsMapTable];
        
        [self->_sortDescriptors makeObjectsPerformSelector:@selector(allowEvaluation)];
        [self updateSortingAttributes];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.backing forKey:@"TRI.objects"];
    [encoder encodeObject:self.sortDescriptors forKey:@"TRI.sortDescriptors"];
    [encoder encodeBool:self.isReversed forKey:@"TRI.isReversed"];
    [encoder encodeBool:self.allowsConcurrentSorting forKey:@"TRI.allowsConcurrent"];
    [encoder encodeBool:self.insertsEqualObjectsFirst forKey:@"TRI.equalFirst"];
    [encoder encodeObject:self.observers forKey:@"TRI.observers"]; //TEST: Encodes conditionally.
    // .subscribers uses block so no encoding.
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





#pragma mark -


#pragma mark Mutations: Adding


- (void)addObject:(NSObject *)object TRI_PUBLIC_API {
    NSUInteger index = [self proposedIndexOfObject:object];
    [self reportWillInsertObject:object atIndex:index];
    [self.backing insertObject:object atIndex:index];
    [self reportDidInsertObject:object atIndex:index];
}


- (void)addObjectsFromCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    [self beginChanges];
    for (NSObject *object in collection) {
        NSUInteger index = [self proposedIndexOfObject:object];
        [self reportWillInsertObject:object atIndex:index];
        [backing insertObject:object atIndex:index];
        [self reportDidInsertObject:object atIndex:index];
    }
    [self endChanges];
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


- (void)setObjects:(NSArray *)array {
    [self reportWillReplaceContent];
    [self.backing setArray:array];
    [self sort];
    [self reportDidReplaceContent];
}





#pragma mark Mutations: Removing


- (void)removeObject:(NSObject *)object atIndex:(NSUInteger)index TRI_PUBLIC_API {
    [self reportWillRemoveObject:object fromIndex:index];
    [self.backing removeObjectAtIndex:index];
    [self reportDidRemoveObject:object fromIndex:index];
}


- (void)removeAllObjects TRI_PUBLIC_API {
    [self reportWillReplaceContent];
    [self.backing removeAllObjects];
    [self reportDidReplaceContent];
}


- (void)removeObject:(NSObject *)object TRI_PUBLIC_API {
    NSUInteger index = [self.backing indexOfObject:object];
    [self removeObjectAtIndex:index];
}


- (void)removeObjectIdenticalTo:(NSObject *)object TRI_PUBLIC_API {
    NSUInteger index = [self.backing indexOfObjectIdenticalTo:object];
    [self removeObjectAtIndex:index];
}


- (void)removeObjectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    if (index != NSNotFound) {
        NSObject *object = [self.backing objectAtIndex:index];
        [self removeObject:object atIndex:index];
    }
}


- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    [self beginChanges];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, __unused BOOL *stop) {
        [self removeObjectAtIndex:index];
    }];
    [self endChanges];
}

- (void)removeObjectsInRange:(NSRange)range TRI_PUBLIC_API {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
    [self removeObjectsAtIndexes:indexes];
}


- (void)removeObjectsInCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    [self beginChanges];
    for (NSObject *object in collection) {
        [self removeObject:object];
    }
    [self endChanges];
}





#pragma mark Mutations: Filtering


- (void)filterUsingPredicate:(NSPredicate *)predicate TRI_PUBLIC_API {
    [self filterUsingBlock:^BOOL(id object, NSUInteger index) {
        return [predicate evaluateWithObject:object substitutionVariables:@{ @"index": @(index) }];
    }];
}


- (void)filterUsingBlock:(BOOL (^)(id, NSUInteger))shouldKeep TRI_PUBLIC_API {
    NSUInteger index = 0;
    NSMutableArray *backing = self.backing;
    [self beginChanges];
    for (NSObject *object in [backing copy]) {
        if ( ! shouldKeep(object, index)) {
            [self removeObject:object atIndex:index];
        }
        else {
            index ++;
        }
    }
    [self endChanges];
}





#pragma mark Mutations: Sorting


@synthesize sortDescriptors = _sortDescriptors;


- (NSArray *)sortDescriptors TRI_PUBLIC_API {
    if ( ! self->_sortDescriptors) {
        // Never nil, set to empty array.
        self->_sortDescriptors = @[];
    }
    return self->_sortDescriptors;
}


- (void)setSortDescriptors:(NSArray *)sortDescriptors TRI_PUBLIC_API {
    self->_sortDescriptors = [sortDescriptors copy];
    [self updateSortingAttributes];
}


@synthesize isReversed = _isReversed;


- (BOOL)isReversed {
    return self->_isReversed;
}


- (void)setReversed:(BOOL)isReversed {
    self->_isReversed = isReversed;
    [self updateSortingAttributes];
}


- (void)updateSortingAttributes {
    NSArray *sortDescriptors = self.sortDescriptors;
    if (sortDescriptors.count > 0) {
        NSSet *keyPaths = [self keyPathsFromSortDescriptors:sortDescriptors];
        self.observedKeyPaths = keyPaths;
        //TODO: Observe key-paths
        BOOL isReversed = self.isReversed;
        [self setCombinedComparator:^NSComparisonResult(id objectA, id objectB) {
            for (NSSortDescriptor *descriptor in sortDescriptors) {
                NSComparisonResult result = [descriptor compareObject:objectA toObject:objectB];
                if (isReversed) result *= -1;
                if (result != NSOrderedSame) return result;
            }
            return NSOrderedSame;
        }];
        [self reportWillSort];
        [self sort];
        [self reportDidSort];
    }
    else {
        self.combinedComparator = nil;
        self.observedKeyPaths = nil;
        //TODO: Un-observe key-paths
    }
}


- (NSSet *)keyPathsFromSortDescriptors:(NSArray *)sortDescriptors {
    NSMutableSet *keyPaths = [NSMutableSet setWithCapacity:sortDescriptors.count];
    for (NSSortDescriptor *descriptor in sortDescriptors) {
        if (descriptor.key) {
            [keyPaths addObject:descriptor.key];
        }
    }
    return keyPaths;
}


- (void)sort {
    NSComparator comparator = self.combinedComparator;
    if (comparator) {
        NSSortOptions options = NSSortStable;
        if (self.allowsConcurrentSorting) {
            options |= NSSortConcurrent;
        }
        [self.backing sortWithOptions:options usingComparator:comparator];
    }
}



- (void)sortObject:(NSObject *)object {
    NSMutableArray *backing = self.backing;
    NSUInteger sourceIndex = [backing indexOfObjectIdenticalTo:object];
    
    [self reportWillMoveObject:object fromIndex:sourceIndex];
    [backing removeObjectAtIndex:sourceIndex];
    NSUInteger destinationIndex = [self proposedIndexOfObject:object];
    [backing insertObject:object atIndex:destinationIndex];
    [self reportDidMoveObject:object fromIndex:sourceIndex toIndex:destinationIndex];
}





#pragma mark -
#pragma mark Observations: Managing


- (void)addObserver:(NSObject<TRISortedArrayObserver> *)observer TRI_PUBLIC_API {
    [self.observers addObject:observer];
    if (self.mutations > 0) {
        if ([observer respondsToSelector:@selector(sortedArrayWillBeginChanges:)]) {
            [observer sortedArrayWillBeginChanges:self];
        }
    }
}


- (void)removeObserver:(NSObject<TRISortedArrayObserver> *)observer TRI_PUBLIC_API {
    [self.observers removeObject:observer];
}


- (void)addSubscriber:(NSObject *)subscriber block:(TRISortedArraySubscribtionBlock)block TRI_PUBLIC_API {
    NSMutableArray *subscriptions = [self.subscriptions objectForKey:subscriber];
    if ( ! subscriptions) {
        subscriptions = [NSMutableArray new];
        [self.subscriptions setObject:subscriptions forKey:subscriber];
    }
    [subscriptions addObject:block];
}


- (void)removeSubscriber:(NSObject *)subscriber TRI_PUBLIC_API {
    [self.subscriptions removeObjectForKey:subscriber];
}





#pragma mark Observations: Grouping


- (void)performChanges:(void (^)(void))block TRI_PUBLIC_API {
    [self beginChanges];
    block();
    [self endChanges];
}


- (void)beginChanges {
    NSInteger mutations = self.mutations;
    BOOL wasMutating = (mutations > 0);
    mutations ++;
    BOOL isMutating = (mutations > 0);
    self.mutations = mutations;
    
    if ( ! wasMutating && isMutating) {
        [self reportWillBeginChanges];
    }
}


- (void)endChanges {
    NSInteger mutations = self.mutations;
    BOOL wasMutating = (mutations > 0);
    mutations --;
    BOOL isMutating = (mutations > 0);
    self.mutations = mutations;
    
    if (wasMutating && ! isMutating) {
        [self reportDidEndChanges];
    }
}





#pragma mark Observations: Reporting


- (void)reportWillBeginChanges {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayWillBeginChanges:)]) {
            [observer sortedArrayWillBeginChanges:self];
        }
    }
}


- (void)reportDidEndChanges {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayDidEndChanges:)]) {
            [observer sortedArrayDidEndChanges:self];
        }
    }
    for (NSObject *subscriber in self.subscriptions) {
        NSArray *subscribtions = [self.subscriptions objectForKey:subscriber];
        for (TRISortedArraySubscribtionBlock block in subscribtions) {
            block(subscriber, self);
        }
    }
}


- (void)reportWillReplaceContent {
    [self beginChanges];
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayWillReplaceContent:)]) {
            [observer sortedArrayWillReplaceContent:self];
        }
    }
}


- (void)reportDidReplaceContent {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayDidReplaceContent:)]) {
            [observer sortedArrayDidReplaceContent:self];
        }
    }
    [self endChanges];
}


- (void)reportWillSort {
    [self beginChanges];
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayWillSort:)]) {
            [observer sortedArrayWillSort:self];
        }
    }
}


- (void)reportDidSort {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArrayDidSort:)]) {
            [observer sortedArrayDidSort:self];
        }
    }
    [self endChanges];
}


- (void)reportWillInsertObject:(NSObject *)object atIndex:(NSUInteger)index {
    [self beginChanges];
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:willInsertObject:atIndex:)]) {
            [observer sortedArray:self willInsertObject:object atIndex:index];
        }
    }
}


- (void)reportDidInsertObject:(NSObject *)object atIndex:(NSUInteger)index {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:didInsertObject:atIndex:)]) {
            [observer sortedArray:self didInsertObject:object atIndex:index];
        }
    }
    [self endChanges];
}


- (void)reportWillRemoveObject:(NSObject *)object fromIndex:(NSUInteger)index {
    [self beginChanges];
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:willRemoveObject:fromIndex:)]) {
            [observer sortedArray:self willRemoveObject:object fromIndex:index];
        }
    }
}


- (void)reportDidRemoveObject:(NSObject *)object fromIndex:(NSUInteger)index {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:didRemoveObject:fromIndex:)]) {
            [observer sortedArray:self didRemoveObject:object fromIndex:index];
        }
    }
    [self endChanges];
}


- (void)reportWillMoveObject:(NSObject *)object fromIndex:(NSUInteger)sourceIndex {
    [self beginChanges];
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:willMoveObject:fromIndex:)]) {
            [observer sortedArray:self willMoveObject:object fromIndex:sourceIndex];
        }
    }
}


- (void)reportDidMoveObject:(NSObject *)object fromIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    for (NSObject<TRISortedArrayObserver> *observer in self.observers) {
        if ([observer respondsToSelector:@selector(sortedArray:didMoveObject:fromIndex:toIndex:)]) {
            [observer sortedArray:self didMoveObject:object fromIndex:sourceIndex toIndex:destinationIndex];
        }
    }
    [self endChanges];
}





#pragma mark -


#pragma mark NSArray: Creating


- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithObjects:objects count:count];
    return [self initWithBacking:mutable];
}


- (instancetype)initWithContentsOfURL:(NSURL *)URL TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithContentsOfURL:URL];
    return [self initWithBacking:mutable];
}


- (instancetype)initWithContentsOfFile:(NSString *)path TRI_PUBLIC_API {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}


+ (instancetype)arrayWithContentsOfURL:(NSURL *)URL TRI_PUBLIC_API {
    return [[self alloc] initWithContentsOfURL:URL];
}


+ (instancetype)arrayWithContentsOfFile:(NSString *)path TRI_PUBLIC_API {
    return [[self alloc] initWithContentsOfFile:path];
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





#pragma mark NSArray: Querying


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





#pragma mark NSArray: Finding


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


- (id)firstObjectCommonWithArray:(NSArray *)other TRI_PUBLIC_API {
    return [self.backing firstObjectCommonWithArray:other];
}


- (NSArray *)pathsMatchingExtensions:(NSArray *)filterTypes {
    return [self.backing pathsMatchingExtensions:filterTypes];
}





#pragma mark NSArray: Enumerating


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





#pragma mark NSArray: Copying


- (NSArray *)copy TRI_PUBLIC_API {
    return [self.backing copy];
}


- (NSArray *)copyWithZone:(NSZone *)zone TRI_PUBLIC_API {
    return [self.backing copyWithZone:zone];
}


- (NSMutableArray *)mutableCopy TRI_PUBLIC_API {
    return [self.backing mutableCopy];
}


- (NSMutableArray *)mutableCopyWithZone:(NSZone *)zone TRI_PUBLIC_API {
    return [self.backing mutableCopyWithZone:zone];
}





#pragma mark NSArray: Deriving


- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)other TRI_PUBLIC_API {
    return [self.backing arrayByAddingObjectsFromArray:other];
}


- (NSArray *)subarrayWithRange:(NSRange)range TRI_PUBLIC_API {
    return [self.backing subarrayWithRange:range];
}


- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate TRI_PUBLIC_API {
    return [self.backing filteredArrayUsingPredicate:predicate];
}





#pragma mark NSArray: Sorting


- (NSData *)sortedArrayHint {
    return [self.backing sortedArrayHint];
}


- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))comparator context:(void *)context {
    return [self.backing sortedArrayUsingFunction:comparator context:context];
}


- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(__strong id, __strong id, void *))comparator context:(void *)context hint:(NSData *)hint {
    return [self.backing sortedArrayUsingFunction:comparator context:context hint:hint];
}


- (NSArray *)sortedArrayUsingDescriptors:(NSArray *)sortDescriptors {
    return [self.backing sortedArrayUsingDescriptors:sortDescriptors];
}


- (NSArray *)sortedArrayUsingComparator:(NSComparator)comparator {
    return [self.backing sortedArrayUsingComparator:comparator];
}


- (NSArray *)sortedArrayWithOptions:(NSSortOptions)options usingComparator:(NSComparator)comparator {
    return [self.backing sortedArrayWithOptions:options usingComparator:comparator];
}





#pragma mark NSArray: Key-Value Coding


- (id)valueForKey:(NSString *)key {
    return [self.backing valueForKey:key];
}


- (void)setValue:(id)value forKey:(NSString *)key {
    [self.backing setValue:value forKey:key];
}





#pragma mark NSArray: Describing


- (NSString *)description {
    return [self.backing description];
}


- (NSString *)descriptionWithLocale:(id)locale {
    return [self.backing descriptionWithLocale:locale];
}


- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    return [self.backing descriptionWithLocale:locale indent:level];
}


- (NSString *)debugDescription {
    return [self.backing debugDescription];
}


- (NSString *)componentsJoinedByString:(NSString *)separator {
    return [self.backing componentsJoinedByString:separator];
}





#pragma mark NSArray: Serializing


- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile {
    return [self.backing writeToFile:path atomically:useAuxiliaryFile];
}


- (BOOL)writeToURL:(NSURL *)URL atomically:(BOOL)atomically {
    return [self.backing writeToURL:URL atomically:atomically];
}







@end


