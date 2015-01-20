//
//  TRISortedArrayObserver.h
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import Foundation;
@class TRISortedArray;





//! Protocol used by \c TRISortedArray to notify about its mutations. All methods are optional.
@protocol TRISortedArrayObserver <NSObject> @optional


#pragma mark - Grouping

//! Called before every group of changes. Group of changes may contain zero, one or more changes made at once.
- (void)sortedArrayWillBeginChanges:(TRISortedArray *)sortedArray;
//! Called after every group of changes. Group of changes may contain zero, one or more changes made at once.
- (void)sortedArrayDidEndChanges:(TRISortedArray *)sortedArray;


#pragma mark -
#pragma mark Replacing

//! Called before the contents are replaced using \c -setObjects: or \c -removeAllObjects methods.
- (void)sortedArrayWillReplaceContent:(TRISortedArray *)sortedArray;
//! Called after the contents are replaced using \c -setObjects: or \c -removeAllObjects methods.
- (void)sortedArrayDidReplaceContent:(TRISortedArray *)sortedArray;


#pragma mark Sorting

//! Called before the all objects are sorted by using \c -setSortDescriptors: or \c -setReversed: methods.
- (void)sortedArrayWillSort:(TRISortedArray *)sortedArray;
//! Called after the all objects are sorted by using \c -setSortDescriptors: or \c -setReversed: methods.
- (void)sortedArrayDidSort:(TRISortedArray *)sortedArray;


#pragma mark Inserting

//! Called before an object is inserted using \c -addObject: or \c -addObjectsFromCollection: methods.
- (void)sortedArray:(TRISortedArray *)sortedArray willInsertObject:(id)object atIndex:(NSUInteger)index;
//! Called after an object is inserted using \c -addObject: or \c -addObjectsFromCollection: methods.
- (void)sortedArray:(TRISortedArray *)sortedArray didInsertObject:(id)object atIndex:(NSUInteger)index;


#pragma mark Removing

//! Called before an object is removed using any of the \c -remove... or \c -filter... methods.
- (void)sortedArray:(TRISortedArray *)sortedArray willRemoveObject:(id)object fromIndex:(NSUInteger)index;
//! Called after an object is removed using any of the \c -remove... or \c -filter... methods.
- (void)sortedArray:(TRISortedArray *)sortedArray didRemoveObject:(id)object fromIndex:(NSUInteger)index;


#pragma mark Moving

//! Called before an object is moved to another index, which is triggered by KVO.
- (void)sortedArray:(TRISortedArray *)sortedArray willMoveObject:(id)object fromIndex:(NSUInteger)sourceIndex;
//! Called after an object is moved to another index, which is triggered by KVO.
- (void)sortedArray:(TRISortedArray *)sortedArray didMoveObject:(id)object fromIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;


@end



#pragma mark -

//! Type of the subscription block registered with \c TRISortedArray.
typedef void (^TRISortedArraySubscribtionBlock)(id subscriber, TRISortedArray *sortedArray);


