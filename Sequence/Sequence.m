#import "Sequence.h"

const void *emptySeq;

@interface Seq (Internal) 

- (id)reduce:(Reduce)reduce seed:(id)seed;
- (id)concat:(id)tail;

@end

@interface PullSeqImpl : Seq {
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
        if ([item respondsToSelector:@selector(copy)])
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

const int beforeHead = 0, inHead = 1, beforeTail = 2, inTail = 3, end = 4;

- (id)_concat:(id)tail {
    if (!tail)
        return self;
    
    tail = [tail seq];
    
    if (![tail isKindOfClass:[PullSeqImpl class]])
        [NSException raise:@"IncompatibleSequenceType" format:@"Cannot concat pull sequence with '%@'", tail];
    
    return [[[PullSeqImpl alloc] initWithPull:^ Func () {
        PullSeqImpl *tailImpl = (PullSeqImpl *)tail;
        
        __block Func next = nil;
        __block int state = 0;
        
        return [[^ id () {            
            id nextItem = nil;
            
        advance:
            switch (state) {
                case beforeHead:
                    if (single) {
                        state = beforeTail;
                        nextItem = single;
                        goto yieldNext;
                    }
                    
                    if (impl) {
                        next = impl();
                        state = inHead;
                        goto advance;
                    }
                    
                    state = beforeTail;
                    goto advance;
                    
                case inHead:
                case inTail:
                    nextItem = next();
                    
                    if (!nextItem) {
                        state = state == inHead ? beforeTail : end;
                        goto advance;
                    }
                    goto yieldNext;
                    
                case beforeTail:
                    if (!tailImpl) {
                        state = end;
                        goto yieldNext;
                    }
                    
                    if (tailImpl->single) {
                        state = end;
                        nextItem = tailImpl->single;
                        goto yieldNext;
                    }
                    
                    if (tailImpl->impl) {
                        next = tailImpl->impl();
                        state = inTail;
                        goto advance;
                    }
                    
                    // (implicit fall-through to end)
                case end:
                    return nil;
            }
        yieldNext:
            return nextItem;
            
        } copy] autorelease];
    }] autorelease];
}

- (id)_itemAtIndex:(NSUInteger)index {
    if (single)
        if (index == 0)
            return single;
        else
            return nil;
    else {
        Func next = impl();
        id item = nil;
        for (NSUInteger i = 0; (item = next()); i++) {
            if (i == index)
                return item;
        }
        return nil;
    }
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

+ (id)empty { return emptySeq; }

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
    
    BOOL isEnumerator = [self isKindOfClass:[NSEnumerator class]];
    
    if (isEnumerator || [self respondsToSelector:@selector(objectEnumerator)]) {
        return [Seq pull:^ Func () {
            NSEnumerator *enumerator = isEnumerator ? self : [self performSelector:@selector(objectEnumerator)];
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
            ^ id (id acc, id next) { return predicate(next) ? [acc _concat:[next seq]] : acc; } 
                   seed:[Seq empty]];
}

- (void)each:(Action)action {
    id s = [self seq];
    
    [s map:^ id (id i) { 
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
    return [[[self seq] _reduce:^ id (id acc, id i) { 
        return [NSNumber numberWithBool:[acc boolValue] && predicate(i)];
    } seed:[NSNumber numberWithBool:YES]] boolValue];
}

- (BOOL)any:(Predicate)predicate {
    return [[[self seq] _reduce:^ id (id acc, id i) { 
        return [NSNumber numberWithBool:[acc boolValue] || predicate(i)];
    } seed:[NSNumber numberWithBool:NO]] boolValue];
}

- (NSUInteger)size {
    return [[[self seq] _reduce:^ id (id acc, id i) {
        return [NSNumber numberWithUnsignedInteger:[acc unsignedIntegerValue] + 1];
    } seed:[NSNumber numberWithUnsignedInteger:0]] unsignedIntegerValue];
}

@end