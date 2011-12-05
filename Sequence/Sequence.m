#import "Sequence.h"

@interface Seq (Internal) 

- (id)reduce:(Reduce)reduce seed:(id)seed;
- (id)concat:(id)tail;

@end

@interface PullSeqImpl : NSObject {
    PullSeq impl;
}
@end

@implementation PullSeqImpl

- (id)initWithPull:(PullSeq)pull {
    if ((self = [super init])) {
        impl = [pull copy];
    }
    return self;
}

- (void)dealloc {
    [impl release];
    [super dealloc];
}

- (id)reduce:(Reduce)reduce seed:(id)seed {
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

- (id)concat:(id)tail {
    if (!tail)
        return self;
    
    if (tail && ![tail isKindOfClass:[PullSeqImpl class]])
        [NSException raise:@"IncompatibleSequenceType" format:@"Cannot concat push sequence with '%@'", tail];
    
    return [[[PullSeqImpl alloc] initWithPull:^ Func () {
        PullSeqImpl *tailImpl = (PullSeqImpl *)tail;
        __block Func next = impl();
        __block BOOL headFinished = NO;
        return [[^ id () {
            id i = next();
            if (!i && !headFinished) {
                headFinished = YES;
                next = tailImpl->impl();
                i = next();
            }
            return i;
        } copy] autorelease];
    }] autorelease];
}

@end

@interface PushSeqImpl : Seq {
    PushSeq impl;
}
@end

@implementation PushSeqImpl

- (id)initWithPush:(PushSeq)push {
    if ((self = [super init])) {
        impl = [push copy];
    }
    return self;
}

- (void)dealloc {
    [impl release];
    [super dealloc];
}

- (id)reduce:(Reduce)reduce seed:(id)seed {
    __block id result = seed;
    impl(^ void (id i) {
        result = reduce(result, i);
    });
    return result;
}

- (id)concat:(id)tail {
    if (!tail)
        return self;
    
    if ([tail isKindOfClass:[NSArray class]])
        tail = [tail seq];
    
    if (![tail isKindOfClass:[PushSeqImpl class]])
        [NSException raise:@"IncompatibleSequenceType" format:@"Cannot concat push sequence with '%@'", tail];
    
    return [[[PushSeqImpl alloc] initWithPush:^ void(void (^push)(id)) {
        impl(push);
        PushSeqImpl *tailImpl = (PushSeqImpl *)tail;
        tailImpl->impl(push);
    }] autorelease];
}

@end

@implementation Seq

+ (id)push:(PushSeq)push {
    return [[[PushSeqImpl alloc] initWithPush:push] autorelease];
}

+ (id)pull:(PullSeq)pull {
    return [[[PullSeqImpl alloc] initWithPull:pull] autorelease];
}

+ (id)empty { return nil; }
- (id)map:(Map)map { return nil; }
- (id)concat:(id)tail { return nil; }

@end

@implementation NSObject (Sequence)

- (id)seq {
    if ([self isKindOfClass:[Seq class]])
        return self;
    
    if ([self conformsToProtocol:@protocol(NSFastEnumeration)])
        return [Seq push:^ void(void (^push)(id)) {
            for (id object in (id<NSFastEnumeration>)self) {
                push(object);
            }
        }];
    
    return [[NSArray arrayWithObject:self] seq];
}

- (NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    [[self seq] each:^ void (id i) { [result addObject:i]; }];
    
    return [[result copy] autorelease];
}

- (id)map:(Map)map {
    return [[self seq] reduce:^ id (id acc, id i) { return [acc concat:map(i)]; } seed:[Seq empty]];
}

- (id)filter:(Predicate)predicate {
    return [[self seq] reduce:
            ^ id (id acc, id next) { return predicate(next) ? [acc concat:[next seq]] : acc; } 
                   seed:[Seq empty]];
}

- (void)each:(Action)action {
    [[self seq] map:^ id (id i) { action(i); return nil; }];
}

- (id)reduce:(Reduce)reduce seed:(id)seed {
    return [[self seq] reduce:reduce seed:seed];
}

- (id)concat:(id)tail {
    return [[self seq] concat:tail];
}

- (BOOL)all:(Predicate)predicate {
    return [[[self seq] reduce:^ id (id acc, id i) { 
        return [NSNumber numberWithBool:[acc boolValue] && predicate(i)];
    } seed:[NSNumber numberWithBool:YES]] boolValue];
}

- (BOOL)any:(Predicate)predicate {
    return [[[self seq] reduce:^ id (id acc, id i) { 
        return [NSNumber numberWithBool:[acc boolValue] || predicate(i)];
    } seed:[NSNumber numberWithBool:NO]] boolValue];
}

- (NSUInteger)size {
    return [[[self seq] reduce:^ id (id acc, id i) {
        return [NSNumber numberWithUnsignedInteger:[acc unsignedIntegerValue] + 1];
    } seed:[NSNumber numberWithUnsignedInteger:0]] unsignedIntegerValue];
}

@end