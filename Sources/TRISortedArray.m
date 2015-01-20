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
        [self sortDescriptorsChanged];
    }
    return self;
}


- (TRISortedArray *)sortedCopy {
    TRISortedArray *copy = [[self.class alloc] initWithBacking:[self.backing mutableCopy]];
    copy.sortDescriptors = self.sortDescriptors;
    copy.allowsConcurrentSorting = self.allowsConcurrentSorting;
    copy.insertsEqualObjectsFirst = self.insertsEqualObjectsFirst;
    return copy;
}





#pragma mark Coding


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self->_backing = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:@"TRI.objects"] ?: [NSMutableArray new];
        
        NSArray *sortDescriptors = [decoder decodeObjectOfClass:[NSArray class] forKey:@"TRI.sortDescriptors"];
        self->_allowsConcurrentSorting = [decoder decodeBoolForKey:@"TRI.allowsConcurrent"];
        self->_insertsEqualObjectsFirst = [decoder decodeBoolForKey:@"TRI.equalFirst"];
        
        self->_observers = [decoder decodeObjectOfClass:[NSHashTable class] forKey:@"TRI.observers"] ?: [NSHashTable weakObjectsHashTable];
        self->_subscriptions = [NSMapTable weakToStrongObjectsMapTable];
        
        [sortDescriptors makeObjectsPerformSelector:@selector(allowEvaluation)];
        self->_sortDescriptors = sortDescriptors; // Setter is needed.
        [self sortDescriptorsChanged];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.backing forKey:@"TRI.objects"];
    [encoder encodeObject:self.sortDescriptors forKey:@"TRI.sortDescriptors"];
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
    [self beginChanges];
    [self.backing insertObject:object atIndex:index];
    [self endChanges];
}


- (void)addObjectsFromCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    [self beginChanges];
    for (NSObject *object in collection) {
        NSUInteger index = [self proposedIndexOfObject:object];
        [backing insertObject:object atIndex:index];
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





#pragma mark Mutations: Removing


- (void)removeAllObjects TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeAllObjects];
    [self endChanges];
}


- (void)removeObject:(NSObject *)object TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeObject:object];
    [self endChanges];
}


- (void)removeObjectIdenticalTo:(NSObject *)object TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeObjectIdenticalTo:object];
    [self endChanges];
}


- (void)removeObjectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeObjectAtIndex:index];
    [self endChanges];
}


- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeObjectsAtIndexes:indexes];
    [self endChanges];
}

- (void)removeObjectsInRange:(NSRange)range TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing removeObjectsInRange:range];
    [self endChanges];
}


- (void)removeObjectsInCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    [self beginChanges];
    for (NSObject *object in collection) {
        [backing removeObject:object];
    }
    [self endChanges];
}





#pragma mark Mutations: Filtering


- (void)filterUsingPredicate:(NSPredicate *)predicate TRI_PUBLIC_API {
    [self beginChanges];
    [self.backing filterUsingPredicate:predicate];
    [self endChanges];
}


- (void)filterUsingBlock:(BOOL (^)(id, NSUInteger))shouldKeep TRI_PUBLIC_API {
    NSUInteger index = 0;
    NSMutableArray *backing = self.backing;
    [self beginChanges];
    for (NSObject *object in [backing copy]) {
        if ( ! shouldKeep(object, index)) {
            [backing removeObjectAtIndex:index];
        }
        index ++;
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
    [self sortDescriptorsChanged];
}


- (void)sortDescriptorsChanged {
    NSArray *sortDescriptors = self.sortDescriptors;
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
        [self beginChanges];
        [self.backing sortWithOptions:options usingComparator:comparator];
        [self endChanges];
    }
}


- (void)sortObject:(NSObject *)object TRI_PUBLIC_API {
    if ([self.backing containsObject:object]) {
        [self beginChanges];
        [self removeObject:object];
        [self addObject:object];
        [self endChanges];
    }
}


- (void)sortObjectIdenticalTo:(id)object TRI_PUBLIC_API {
    if ([self.backing indexOfObjectIdenticalTo:object] != NSNotFound) {
        [self beginChanges];
        [self removeObjectIdenticalTo:object];
        [self addObject:object];
        [self endChanges];
    }
}


- (void)sortObjectAtIndex:(NSUInteger)index TRI_PUBLIC_API {
    id object = [self.backing objectAtIndex:index];
    [self beginChanges];
    [self removeObjectAtIndex:index];
    [self addObject:object];
    [self endChanges];
}


- (void)sortObjectAtIndexes:(NSIndexSet *)indexes TRI_PUBLIC_API {
    NSArray *objects = [self.backing objectsAtIndexes:indexes];
    [self beginChanges];
    [self removeObjectsAtIndexes:indexes];
    [self addObjectsFromCollection:objects];
    [self endChanges];
}


- (void)sortObjectsInRange:(NSRange)range TRI_PUBLIC_API {
    NSArray *objects = [self.backing subarrayWithRange:range];
    [self beginChanges];
    [self removeObjectsInRange:range];
    [self addObjectsFromCollection:objects];
    [self endChanges];
}


- (void)sortObjectsInCollection:(NSObject<NSFastEnumeration> *)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    // Find only those that are actually contained.
    NSMutableArray *subcollection = [NSMutableArray new];
    for (NSObject *object in collection) {
        if ([backing containsObject:object]) {
            [subcollection addObject:object];
        }
    }
    [self beginChanges];
    [self removeObjectsInCollection:subcollection];
    [self addObjectsFromCollection:subcollection];
    [self endChanges];
}





#pragma mark -
#pragma mark Observations: Managing


- (void)addObserver:(NSObject<TRISortedArrayObserver> *)observer TRI_PUBLIC_API {
    [self.observers addObject:observer];
    if (self.mutations > 0) {
        //TODO: Report begin changes
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





#pragma mark Observations: Reporting


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
        //TODO: Report begin changes.
    }
}


- (void)endChanges {
    NSInteger mutations = self.mutations;
    BOOL wasMutating = (mutations > 0);
    mutations --;
    BOOL isMutating = (mutations > 0);
    self.mutations = mutations;
    
    if (wasMutating && ! isMutating) {
        //TODO: Report end changes.
    }
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


