
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

// converts reciever into a sequence type for use with the other methods 
// defined in the sequence category. for Cocoa collections (NSArray, 
// NSDictionary, NSSet) the returned sequence contains the items in the
// collection. for all other objects, a single-item sequence containing 
// the receiver is returned.
- (id)seq;

// the following methods always convert the receiver to a sequence type 
// using -[NSObject seq] before doing anything else.

// materializes the receiver into an NSArray.
- (NSArray *)array;

// all of these return sequence types
- (id)map:(Map)map;
- (id)reduce:(Reduce)reduce seed:(id)seed;
- (id)concat:(id)tail;
- (id)filter:(Predicate)predicate;

// returns true if all of the items in the sequence satisfy the predicate
- (BOOL)all:(Predicate)predicate;

// returns true if any of the items in the sequence satisfy the predicate
- (BOOL)any:(Predicate)predicate;

// calls the action for each item in the sequence
- (void)each:(Action)action;

// returns the number of items in the sequence
- (NSUInteger)size;

@end
