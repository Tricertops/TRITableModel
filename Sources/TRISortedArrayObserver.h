//
//  TRISortedArrayObserver.h
//  TRITableModel
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import Foundation;
@class TRISortedArray;





@protocol TRISortedArrayObserver <NSObject> @optional


#pragma mark - Grouping

- (void)sortedArrayWillBeginChanges:(TRISortedArray *)sortedArray;
- (void)sortedArrayDidEndChanges:(TRISortedArray *)sortedArray;


#pragma mark - Mutating

- (void)sortedArrayWillReplaceContent:(TRISortedArray *)sortedArray;
- (void)sortedArrayDidReplaceContent:(TRISortedArray *)sortedArray;

- (void)sortedArray:(TRISortedArray *)sortedArray didInsertObject:(id)object atIndex:(NSUInteger)index;
- (void)sortedArray:(TRISortedArray *)sortedArray didRemoveObject:(id)object fromIndex:(NSUInteger)index;
- (void)sortedArray:(TRISortedArray *)sortedArray didMoveObject:(id)object fromIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;


@end



typedef void (^TRISortedArraySubscribtionBlock)(TRISortedArray *sortedArray);


