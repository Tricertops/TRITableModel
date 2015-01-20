//
//  TRISordedArrayTests.m
//  TRISordedArrayTests
//
//  Created by Martin Kiss on 19.1.15.
//  Copyright (c) 2015 Triceratops. All rights reserved.
//

@import XCTest;
@import TRITableModel;





@interface TRISordedArrayTests : XCTestCase

@property (readonly) NSSortDescriptor *sortAscending;
@property (readonly) NSArray *firstNames;

@end





@implementation TRISordedArrayTests





#pragma mark Helpers


- (NSSortDescriptor *)sortAscending {
    return [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
}


- (NSArray *)firstNames {
    return @[
             @"Bob",
             @"Eve",
             @"Adam",
             @"Daniel",
             @"Clark",
             ];
}





#pragma mark -
#pragma mark Creating: Returns Subclass


- (void)test_ReturnsSubclass_array {
    TRISortedArray *array = [TRISortedArray array];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_arrayWithObject {
    TRISortedArray *array = [TRISortedArray arrayWithObject:self];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_arrayWithObjects {
    TRISortedArray *array = [TRISortedArray arrayWithObjects:self, self, nil];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_arrayWithObjects_count {
    id buffer[] = { self, self };
    TRISortedArray *array = [TRISortedArray arrayWithObjects:buffer count:sizeof(buffer)/sizeof(id)];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_arrayWithArray {
    TRISortedArray *array = [TRISortedArray arrayWithArray:@[ self, self ]];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_initWithObjects {
    TRISortedArray *array = [[TRISortedArray alloc] initWithObjects:self, self, nil];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_initWithArray {
    TRISortedArray *array = [[TRISortedArray alloc] initWithArray:@[ self, self ]];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}


- (void)test_ReturnsSubclass_initWithArray_copyItems {
    TRISortedArray *array = [[TRISortedArray alloc] initWithArray:@[ @"", @0 ] copyItems:YES];
    XCTAssertTrue([array isKindOfClass:[TRISortedArray class]]);
}





#pragma mark Creating: Correct Content


- (void)test_CorrectContent_init {
    TRISortedArray *array = [[TRISortedArray alloc] init];
    XCTAssertEqual(array.count, 0);
    XCTAssertNil(array.firstObject);
}


- (void)test_CorrectContent_initWithCapacity {
    TRISortedArray *array = [[TRISortedArray alloc] initWithCapacity:10];
    XCTAssertEqual(array.count, 0);
    XCTAssertNil(array.firstObject);
}


- (void)test_CorrectContent_initWithArray_sortDescriptors {
    TRISortedArray *array = [[TRISortedArray alloc] initWithArray:self.firstNames sortDescriptors:nil];
    XCTAssertEqual(array.count, 5);
    XCTAssertEqual(array[0], self.firstNames[0]);
    XCTAssertEqual(array[1], self.firstNames[1]);
    XCTAssertEqual(array[2], self.firstNames[2]);
    XCTAssertEqual(array[3], self.firstNames[3]);
    XCTAssertEqual(array[4], self.firstNames[4]);
}








@end


