#import "Sequence.h"

const void *emptySeq;

enum {
    ConcatStateBeforeHead,
    ConcatStateHead,
    ConcatStateBeforeTail,
    ConcatStateTail,
    ConcatStateEnd
};
typedef NSInteger ConcatState;

@class PullSeqImpl;

@interface PullSeqConcat : NSObject {
    PullSeqImpl *head, *tail;
    Func next;
    ConcatState state;
}

- (id)initWithHead:(PullSeqImpl *)leHead tail:(PullSeqImpl *)leTail;
- (id)next;

@end

@interface PullSeqImpl : Seq {
@public
    PullSeq impl;
    id single;
}
@end

@implementation PullSeqImpl

- (id)initWithPull:(PullSeq)pull {
    if ((self = [super init])) {
        impl = [pull copy];
    }
    return self;
}

- (id)initWithItem:(id)item {
    if ((self = [super init])) {
        if ([item conformsToProtocol:@protocol(NSCopying)])
            single = [item copy];
        else 
            single = [item retain];
    }
    return self;
}

- (void)dealloc {
    [single release];
    [impl release];
    [super dealloc];
}

- (id)_reduce:(Reduce)reduce seed:(id)seed {
    if (self == emptySeq) return seed;
    
    Func next = impl();
    while (YES) {
        id i = next();
        if (i)
            seed = reduce(seed, i);
        else
            break;
    };
    
    return seed;
}


- (id)_concat:(id)tail {
    if (!tail)
        return self;
    
    tail = [tail seq];
    
    if (![tail isKindOfClass:[PullSeqImpl class]])
        [NSException raise:@"IncompatibleSequenceType" format:@"Cannot concat pull sequence with '%@'", tail];
    
    return [[[PullSeqImpl alloc] initWithPull:^ Func () {
        PullSeqImpl *tailImpl = (PullSeqImpl *)tail;
        PullSeqConcat *concat = [[[PullSeqConcat alloc] initWithHead:self tail:tailImpl] autorelease];
        return [[^ id () { return [concat next]; } copy] autorelease];
    }] autorelease];
}

- (id)_itemAtIndex:(NSUInteger)index {
    if (single)
        if (index == 0)
            return single;
        else
            return nil;
    else {
        // XXX memoize?
        Func next = impl();
        id item = nil;
        for (NSUInteger i = 0; (item = next()); i++) {
            if (i == index)
                return item;
        }
        return nil;
    }
}


- (BOOL)_any:(Predicate)predicate {
    id item = nil;
    
    if (single)
        return predicate(single);
    else if (impl) {
        for (Func next = impl(); (item = next());)
            if (predicate(item))
                return YES;
        
        return NO;
    }
    return NO;
}

- (BOOL)_all:(Predicate)predicate {
    id item = nil;
    
    if (single)
        return predicate(single);
    else if (impl) {
        for (Func next = impl(); (item = next());)
            if (!predicate(item))
                return NO;
        
        return YES;
    }
    
    return NO;
}

@end

@implementation PullSeqConcat 

- (id)initWithHead:(PullSeqImpl *)leHead tail:(PullSeqImpl *)leTail {
    if ((self = [super init])) {
        head = [leHead retain];
        tail = [leTail retain];
    }
    return self;
}

- (void)dealloc {
    [head release];
    [tail release];
    [super dealloc];
}

- (id)next {
    id nextItem = nil;
    
advance:
    switch (state) {
        case ConcatStateBeforeHead:
            if (head->single) {
                state = ConcatStateBeforeTail;
                nextItem = head->single;
                goto yieldNext;
            }
            
            if (head->impl) {
                next = head->impl();
                state = ConcatStateHead;
                goto advance;
            }
            
            state = ConcatStateBeforeTail;
            goto advance;
            
        case ConcatStateHead:
        case ConcatStateTail:
            nextItem = next();
            
            if (!nextItem) {
                state = state == ConcatStateHead ? ConcatStateBeforeTail : ConcatStateEnd;
                goto advance;
            }
            goto yieldNext;
            
        case ConcatStateBeforeTail:
            if (!tail) {
                state = ConcatStateEnd;
                goto yieldNext;
            }
            
            if (tail->single) {
                state = ConcatStateEnd;
                nextItem = tail->single;
                goto yieldNext;
            }
            
            if (tail->impl) {
                next = tail->impl();
                state = ConcatStateTail;
                goto advance;
            }
            
            // (implicit fall-through to end)
            
        case ConcatStateEnd:
            return nil;
    }
yieldNext:
    return nextItem;
}

@end

@implementation Seq

+ (void)initialize {
    emptySeq = [[PullSeqImpl alloc] init];
}

+ (id)pull:(PullSeq)pull {
    return [[[PullSeqImpl alloc] initWithPull:pull] autorelease];
}

+ (id)withItem:(id)item {
    return [[[PullSeqImpl alloc] initWithItem:item] autorelease];
}

+ (id)empty { return (id)emptySeq; }

+ (id)rangeWithStart:(NSInteger)start end:(NSInteger)end {
    NSMutableArray *array = [NSMutableArray array];
    
    if (end < start) {
        for (NSInteger i = start; i >= end; i--)
            [array addObject:[NSNumber numberWithInteger:i]];
    }
    else {
        for (NSInteger i = start; i <= end; i++)
            [array addObject:[NSNumber numberWithInteger:i]];
    }
    
    return [[array copy] autorelease];
}

@end

@implementation NSObject (Sequence)

- (id)seq {
    if ([self isKindOfClass:[Seq class]])
        return self;
    
    if ([self isKindOfClass:[NSArray class]]) {
        return [Seq pull:^ Func () {
            NSEnumerator *enumerator = [self performSelector:@selector(objectEnumerator)];
            return [[^ id () {
                return [enumerator nextObject];
            } copy] autorelease];
        }];
    }
    
    return [Seq withItem:self];
}

- (NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    id s = [self seq];
    [s each:^ void (id i) { [result addObject:i]; }];
    
    return [[result copy] autorelease];
}

- (id)map:(Map)map {
    return [[self seq] _reduce:^ id (id acc, id i) { return [acc _concat:map(i)]; } seed:[Seq empty]];
}

- (id)filter:(Predicate)predicate {
    return [[self seq] _reduce:
            ^ id (id acc, id next) { return predicate(next) ? [acc _concat:[next seq]] : acc; } seed:[Seq empty]];
}

- (void)each:(Action)action {
    [[self seq] map:^ id (id i) { 
        action(i); 
        return nil; 
    }];
}

- (id)reduce:(Reduce)reduce seed:(id)seed {
    return [[self seq] _reduce:reduce seed:seed];
}

- (id)concat:(id)tail {
    return [[self seq] _concat:tail];
}

- (id)itemAtIndex:(NSUInteger)index {
    return [[self seq] _itemAtIndex:index];
}

- (BOOL)all:(Predicate)predicate {
    return [[self seq] _all:predicate];
}

- (BOOL)any:(Predicate)predicate {
    return [[self seq] _any:predicate];
}

- (NSUInteger)count {
    return [[[self seq] _reduce:^ id (id acc, id i) {
        return [NSNumber numberWithUnsignedInteger:[acc unsignedIntegerValue] + 1];
    } seed:[NSNumber numberWithUnsignedInteger:0]] unsignedIntegerValue];
}

@end