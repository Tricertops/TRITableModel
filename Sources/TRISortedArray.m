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





#pragma mark Creating (Designed)


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





#pragma mark Creating (Extended)


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
#pragma mark Managing Sorting


@synthesize sortDescriptors = _sortDescriptors;


- (NSArray *)sortDescriptors TRI_PUBLIC_API {
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
        [self resort];
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





#pragma mark -
#pragma mark Adding Objects


- (void)addObject:(NSObject *)object TRI_PUBLIC_API {
    NSUInteger index = [self proposedIndexOfObject:object];
    [self.backing insertObject:object atIndex:index];
}


- (void)addObjectsFromCollection:(id<NSFastEnumeration>)collection TRI_PUBLIC_API {
    NSMutableArray *backing = self.backing;
    for (NSObject *object in collection) {
        NSUInteger index = [self proposedIndexOfObject:object];
        [backing insertObject:object atIndex:index];
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


- (NSIndexSet *)proposedIndexesOfObjectsInCollection:(id<NSFastEnumeration>)collection TRI_PUBLIC_API {
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





#pragma mark -
#pragma mark - Removing Objects


- (void)removeAllObjects {
    [self.backing removeAllObjects];
}


- (void)removeObject:(NSObject *)object {
    [self.backing removeObject:object];
}


- (void)removeObjectIdenticalTo:(NSObject *)object {
    [self.backing removeObjectIdenticalTo:object];
}


- (void)removeObjectAtIndex:(NSUInteger)index {
    [self.backing removeObjectAtIndex:index];
}


- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    [self.backing removeObjectsAtIndexes:indexes];
}


- (void)removeObjectsInCollection:(id<NSFastEnumeration>)collection {
    NSMutableArray *backing = self.backing;
    for (NSObject *object in collection) {
        [backing removeObject:object];
    }
}

















































@end


