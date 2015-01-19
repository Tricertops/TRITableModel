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

@end





@implementation TRISordedArrayTests





#pragma mark -
#pragma mark Creating (Returns Subclass)


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








@end


