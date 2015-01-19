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


@property (readonly) NSMutableArray *objects;


- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;


@end





#pragma mark -


@implementation TRISortedArray





#pragma mark Creating (Designed)


- (instancetype)initWithCapacity:(NSUInteger)capacity TRI_PUBLIC_API {
    self = [super init];
    if (self) {
        self->_sortDescriptors = [NSArray new];
        self->_objects = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self->_sortDescriptors = [decoder decodeObjectOfClass:[NSArray class] forKey:@"sortDescriptors"];
        [self->_sortDescriptors makeObjectsPerformSelector:@selector(allowEvaluation)];
        
        self->_objects = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:@"objects"];
    }
    return self;
}


/// Used by convenience initializers that already have NSMutableArray instance that can be used directly.
- (instancetype)initWithMutableObjects:(NSMutableArray *)objects {
    self = [self initWithCapacity:0];
    if (self) {
        self->_objects = objects;
    }
    return self;
}





#pragma mark Creating (Extended)


- (instancetype)init TRI_PUBLIC_API {
    return [self initWithCapacity:0];
}


- (instancetype)initWithArray:(NSArray *)array sortDescriptor:(NSArray *)sortDescriptors TRI_PUBLIC_API {
    self = [self initWithMutableObjects:[array mutableCopy]];
    if (self) {
        // Sort.
        self.sortDescriptors = sortDescriptors;
    }
    return self;
}


- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count TRI_PUBLIC_API {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithObjects:objects count:count];
    return [self initWithMutableObjects:mutable];
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


+ (instancetype)arrayWithContentsOfFile:(NSString *)path {
    NSMutableArray *mutable = [NSMutableArray arrayWithContentsOfFile:path];
    return [[self alloc] initWithMutableObjects:mutable];
}


+ (instancetype)arrayWithContentsOfURL:(NSURL *)URL {
    NSMutableArray *mutable = [NSMutableArray arrayWithContentsOfURL:URL];
    return [[self alloc] initWithMutableObjects:mutable];
}


- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithContentsOfFile:path];
    return [self initWithMutableObjects:mutable];
}


- (instancetype)initWithContentsOfURL:(NSURL *)URL {
    NSMutableArray *mutable = [[NSMutableArray alloc] initWithContentsOfURL:URL];
    return [self initWithMutableObjects:mutable];
}







@end


