
typedef void (^Action)(id);
typedef id (^Func)();

typedef void (^PushSeq)(Action);
typedef Func (^PullSeq)();

typedef id (^Map)(id);
typedef id (^Reduce)(id, id);
typedef BOOL (^Predicate)(id);

@interface Seq : NSObject

+ (id)push:(PushSeq)push;
+ (id)pull:(PullSeq)pull;
+ (id)empty;

@end

@interface NSObject (Sequence) 

- (id)seq;
- (NSArray *)array;

- (id)map:(Map)map;
- (id)reduce:(Reduce)reduce seed:(id)seed;
- (id)concat:(id)tail;
- (id)filter:(Predicate)predicate;
- (BOOL)all:(Predicate)predicate;
- (BOOL)any:(Predicate)predicate;
- (void)each:(Action)action;
- (NSUInteger)size;

@end
