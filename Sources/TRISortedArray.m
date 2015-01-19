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







@end


