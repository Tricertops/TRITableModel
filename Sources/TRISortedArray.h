//
//  TRISortedArray.h
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import Foundation;
#import "TRISortedArrayObserver.h"





//! Partially mutable NSArray, that keeps its objects sorted. The sorting is updated by using KVO.
@interface TRISortedArray : NSArray <NSMutableCopying>


#pragma mark - Creating Array

//! Initializes an empty array.
- (instancetype)init;
//! Initializes an empty array with given capacity. Capacity is used to create to internal storage.
- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
//! Initializes an array with contents of other array and uses sort descriptors to perform sorting.
- (instancetype)initWithArray:(NSArray *)array sortDescriptors:(NSArray *)sortDescriptors;


#pragma mark - Adding Objects

//! Finds an index within the receiver where the given object would be inserted if it was added.
- (NSUInteger)proposedIndexOfObject:(id)object;
//! Inserts a given object into the array’s contents at an appropriate index.
- (void)addObject:(id)object;
//! Inserts all objects from given collection into the array’s contents at appropriate indexes.
- (void)addObjectsFromCollection:(id<NSFastEnumeration>)collection;
/*! Controls the behavior of inserting new objects when an equal object is already contained.
 *  \c NO: Default. Objects are inserted after the last equal object. See \c NSBinarySearchingLastEqual.
 *  \c YES: Objects are inserted before the first equal object. See \c NSBinarySearchingFirstEqual.
 */
@property BOOL insertsEqualObjectsFirst;

//! Sets the receiving array’s elements to those in another given array and performs sorting.
- (void)setObjects:(NSArray *)array;


#pragma mark - Removing Objects

//! Empties the array of all its elements.
- (void)removeAllObjects;
//! Removes all objects equal to a given object.
- (void)removeObject:(id)object;
//! Removes all occurrences of a given object.
- (void)removeObjectIdenticalTo:(id)object;
//! Removes the object at index.
- (void)removeObjectAtIndex:(NSUInteger)index;
//! Removes the objects at the specified indexes.
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
//! Removes the objects within a given range.
- (void)removeObjectsInRange:(NSRange)range;
//! Removes the objects in given collection from the receiving array.
- (void)removeObjectsInCollection:(id<NSFastEnumeration>)collection;


#pragma mark - Filtering Objects

//! Evaluates a given predicate against the array’s content and leaves only objects that match.
- (void)filterUsingPredicate:(NSPredicate *)predicate;
//! Evaluates a given block against the array’s content and leaves only objects that match.
- (void)filterUsingBlock:(BOOL (^)(id object, NSUInteger index))block;


#pragma mark - Sorting Objects

//! Array of \c NSSortDescriptor objects used to perform sorting and insertion. If empty or nil, no sorting is done.
@property (copy) NSArray *sortDescriptors;
//! Whether the result of comparisons is reverted. Default is NO.
@property (setter=setReversed:) BOOL isReversed;
//! Specifies that the sort operation can be concurrent. The objects must be safe against concurrent invocation.
@property BOOL allowsConcurrentSorting;


#pragma mark - Copying

//! Creates an immutable array with the contents of the receiver.
- (NSArray *)copy;
//! Creates a mutable array with the contents of the receiver. The returned array is not mutated by the receiver.
- (NSMutableArray *)mutableCopy;
//! Creates a new instance with the properties of the receiver: object, sort descriptors and sorting options.
- (TRISortedArray *)sortedCopy;


#pragma mark - Comparing

//! Returns YES if the given object is an NSArray and objects at a given index are equal to objects in the receiver.
- (BOOL)isEqual:(NSArray *)other;
//! Returns YES if the receiver and given array contain equal objects in the same indexes.
- (BOOL)isEqualToArray:(NSArray *)other;
//! Returns YES if the receiver and given sorted array has equal contents and sorting options.
- (BOOL)isEqualToSortedArray:(TRISortedArray *)other;


#pragma mark - Observing

//! Registers object to receive detailed notifications about all changes made to the receiver.
- (void)addObserver:(id<TRISortedArrayObserver>)observer;
//! Stops object from receiving detailed notifications about all changes made to the receiver.
- (void)removeObserver:(id<TRISortedArrayObserver>)observer;

/*! Registers block to be invoked after a group of changes is ended.
 *  Subscriber object is held weakly and when it deallocates, the block is automatically released.
 */
- (void)addSubscriber:(id)subscriber block:(TRISortedArraySubscribtionBlock)block;
//! Releases all blocks previously registered for given subscriber. There is no need to call this in dealloc.
- (void)removeSubscriber:(id)subscriber;

//! Wraps the block in a group of changes. All mutations made to the receiver will be reported as one group.
- (void)performChanges:(void (^)(void))block;



@end


