//
//  TRISortedArray.h
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import Foundation;
#import "TRISortedArrayObserver.h"
//TODO: Create custom Typed interface.





@interface TRISortedArray : NSArray <NSMutableCopying>


#pragma mark - Creating Array

- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithArray:(NSArray *)array sortDescriptors:(NSArray *)sortDescriptors;


#pragma mark - Adding Objects

- (NSUInteger)proposedIndexOfObject:(id)object;
- (void)addObject:(id)object;
- (void)addObjectsFromCollection:(id<NSFastEnumeration>)collection;
@property BOOL insertsEqualObjectsFirst;

- (void)setObjects:(NSArray *)array;


#pragma mark - Removing Objects

- (void)removeAllObjects;
- (void)removeObject:(id)object;
- (void)removeObjectIdenticalTo:(id)object;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectsInRange:(NSRange)range;
- (void)removeObjectsInCollection:(id<NSFastEnumeration>)collection;


#pragma mark - Filtering Objects

- (void)filterUsingPredicate:(NSPredicate *)predicate;
- (void)filterUsingBlock:(BOOL (^)(id object, NSUInteger index))block;


#pragma mark - Sorting Objects

@property (copy) NSArray *sortDescriptors;
@property (setter=setReversed:) BOOL isReversed;
@property BOOL allowsConcurrentSorting;


#pragma mark - Copying

- (NSArray *)copy;
- (NSMutableArray *)mutableCopy;
- (TRISortedArray *)sortedCopy;


#pragma mark - Comparing

- (BOOL)isEqualTo:(NSArray *)other;
- (BOOL)isEqualToArray:(NSArray *)other;
- (BOOL)isEqualToSortedArray:(TRISortedArray *)other;


#pragma mark - Observing

- (void)addObserver:(id<TRISortedArrayObserver>)observer;
- (void)removeObserver:(id<TRISortedArrayObserver>)observer;
- (void)addSubscriber:(id)subscriber block:(TRISortedArraySubscribtionBlock)block;
- (void)removeSubscriber:(id)subscriber;

- (void)performChanges:(void (^)(void))block;



@end


