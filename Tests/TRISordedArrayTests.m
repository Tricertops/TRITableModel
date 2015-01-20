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
@property (readonly) NSSortDescriptor *sortDescending;
@property (readonly) NSArray *firstNames;

@end





@interface TRITestPerson : NSObject

@property NSString *firstName;
@property NSString *lastName;

+ (instancetype)first:(NSString *)first last:(NSString *)last;
+ (NSArray *)sortDescriptors;

@end





@implementation TRISordedArrayTests





#pragma mark Helpers


- (NSSortDescriptor *)sortAscending {
    return [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
}


- (NSSortDescriptor *)sortDescending {
    return [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
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





#pragma mark -
#pragma mark Equality


- (void)test_EqualToImmutable {
    NSArray *sortedFirstNames = [self.firstNames sortedArrayUsingDescriptors:@[self.sortAscending]];
    TRISortedArray *array = [TRISortedArray arrayWithArray:sortedFirstNames];
    XCTAssertTrue([array isEqualTo:sortedFirstNames]);
    XCTAssertTrue([array isEqualToArray:sortedFirstNames]);
}


- (void)test_EqualToSorted {
    NSArray *sortedFirstNames = [self.firstNames sortedArrayUsingDescriptors:@[self.sortAscending]];
    TRISortedArray *array = [TRISortedArray arrayWithArray:sortedFirstNames];
    TRISortedArray *copy = [array sortedCopy];
    XCTAssertTrue([array isEqualToSortedArray:copy]);
}





#pragma mark -
#pragma mark Sorting: Insertion Sort


- (void)test_InsertionSort_addObject {
    TRISortedArray *array = [TRISortedArray new];
    array.sortDescriptors = @[self.sortAscending];
    
    [array addObject:@"Daniel"];
    XCTAssertEqualObjects(array[0], @"Daniel");
    
    [array addObject:@"Bob"];
    XCTAssertEqualObjects(array[0], @"Bob");
    XCTAssertEqualObjects(array[1], @"Daniel");
    
    [array addObject:@"Adam"];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Daniel");
    
    [array addObject:@"Eve"];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Daniel");
    XCTAssertEqualObjects(array[3], @"Eve");
    
    [array addObject:@"Clark"];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[3], @"Daniel");
    XCTAssertEqualObjects(array[4], @"Eve");
}


- (void)test_InsertionSort_addObjects {
    TRISortedArray *array = [TRISortedArray new];
    array.sortDescriptors = @[self.sortAscending];
    
    [array addObjectsFromCollection:self.firstNames];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[3], @"Daniel");
    XCTAssertEqualObjects(array[4], @"Eve");
}


- (void)test_InsertionSort_setObjects {
    TRISortedArray *array = [TRISortedArray new];
    array.sortDescriptors = @[self.sortAscending];
    
    [array setObjects:self.firstNames];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[3], @"Daniel");
    XCTAssertEqualObjects(array[4], @"Eve");
}





#pragma mark Sorting: Changing Sort


- (void)test_ChangingSort_setSortDescriptors {
    TRISortedArray *array = [TRISortedArray arrayWithArray:self.firstNames];
    XCTAssertEqualObjects(array, self.firstNames);
    
    array.sortDescriptors = @[self.sortAscending];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[3], @"Daniel");
    XCTAssertEqualObjects(array[4], @"Eve");
    
    array.sortDescriptors = @[self.sortDescending];
    XCTAssertEqualObjects(array[4], @"Adam");
    XCTAssertEqualObjects(array[3], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[1], @"Daniel");
    XCTAssertEqualObjects(array[0], @"Eve");
}


- (void)test_ChangingSort_setReversed {
    TRISortedArray *array = [TRISortedArray arrayWithArray:self.firstNames];
    
    array.sortDescriptors = @[self.sortAscending];
    NSArray *ascendingCopy = [array copy];
    XCTAssertEqualObjects(array[0], @"Adam");
    XCTAssertEqualObjects(array[1], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[3], @"Daniel");
    XCTAssertEqualObjects(array[4], @"Eve");
    
    array.isReversed = YES;
    XCTAssertEqualObjects(array[4], @"Adam");
    XCTAssertEqualObjects(array[3], @"Bob");
    XCTAssertEqualObjects(array[2], @"Clark");
    XCTAssertEqualObjects(array[1], @"Daniel");
    XCTAssertEqualObjects(array[0], @"Eve");
    
    array.isReversed = NO;
    XCTAssertEqualObjects(array, ascendingCopy);
}





#pragma mark Sorting: Live Changes


- (void)test_LiveChanges {
    TRISortedArray *array = [TRISortedArray new];
    array.sortDescriptors = [TRITestPerson sortDescriptors];
    
    TRITestPerson *smith = [TRITestPerson first:@"Adam" last:@"Smith"];
    TRITestPerson *jones = [TRITestPerson first:@"Bob" last:@"Jones"];
    TRITestPerson *taylor = [TRITestPerson first:@"Clark" last:@"Taylor"];
    
    [array addObjectsFromCollection:@[taylor, smith, jones]];
    XCTAssertEqualObjects(array[0], smith);
    XCTAssertEqualObjects(array[1], jones);
    XCTAssertEqualObjects(array[2], taylor);
    
    smith.firstName = @"Daniel";
    XCTAssertEqualObjects(array[0], jones);
    XCTAssertEqualObjects(array[1], taylor);
    XCTAssertEqualObjects(array[2], smith);
    
    [array removeObject:jones];
    XCTAssertEqualObjects(array[0], taylor);
    XCTAssertEqualObjects(array[1], smith);
}





@end





@implementation TRITestPerson

+ (instancetype)first:(NSString *)first last:(NSString *)last {
    TRITestPerson *person = [TRITestPerson new];
    person.firstName = first;
    person.lastName = last;
    return person;
}

+ (NSArray *)sortDescriptors {
    return @[
             [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
             ];
}

@end


