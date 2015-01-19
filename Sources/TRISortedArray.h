//
//  TRISortedArray.h
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import Foundation;



@protocol TRISortedArrayObserver;
//TODO: The Observer protocol
//TODO: Create custom Typed interface.



@interface TRISortedArray : NSArray <NSMutableCopying>


#pragma mark - Creating Sorted Array

- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithArray:(NSArray *)array sortDescriptor:(NSArray *)sortDescriptors;


#pragma mark - Defining Sort Descriptors

@property NSArray *sortDescriptors;
//TODO: BOOL allowsConcurrentSorting


#pragma mark - Adding Objects

- (void)addObject:(id)object;
- (void)addObjectsFromCollection:(id<NSFastEnumeration>)collection;
- (NSUInteger)proposedIndexOfObject:(id)object;
- (NSIndexSet *)proposedIndexesOfObjectsInCollection:(id<NSFastEnumeration>)collection;


#pragma mark - Removing Objects

- (void)removeAllObjects;
- (void)removeObject:(id)object;
- (void)removeObjectIdenticalTo:(id)object;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectsInCollection:(id<NSFastEnumeration>)collection;

- (void)filterUsingPredicate:(NSPredicate *)predicate;
- (void)filterUsingBlock:(BOOL (^)(id object, NSUInteger index))block;


#pragma mark - Copying

- (NSArray *)copy;
- (TRISortedArray *)mutableCopy;


#pragma mark - Observing Changes

- (void)addObserver:(id<TRISortedArrayObserver>)observer;
- (void)removeObserver:(id<TRISortedArrayObserver>)observer;


@end

