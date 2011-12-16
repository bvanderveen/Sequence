
typedef void (^Action)(id);
typedef id (^Func)();

typedef Func (^PullSeq)();

typedef id (^Map)(id);
typedef id (^Reduce)(id, id);
typedef BOOL (^Predicate)(id);

@interface Seq : NSObject

+ (id)pull:(PullSeq)pull;

+ (id)empty;
+ (id)rangeWithStart:(NSInteger)start end:(NSInteger)end; // both inclusive

@end

// the type of a sequence object is internal. 
// sequences should be treated as an opaque handles.
@interface NSObject (Sequence) 

// converts reciever into a sequence type for use with the other methods 
// defined in the Sequence category. if the receiver is NSEnumerator or
// responds to the -[ objectEnumerator] message the returned sequence 
// contains the items returned by the enumerator. for all other receivers,
// a single-item sequence containing the receiver is returned. 
//
// if reciever is a sequence self is returned.
//
// if the receiver supports copy it is called. if you don't want your object 
// copied, consider working with sequences of item-returning functions.
//
// sequences live on the heap and are always returned with an effective retain
// count of 0 (autoreleased).
- (id)seq;


////////////////////////////////////////////////////////////////////////////////
// the following methods always convert the receiver to a sequence type 
// using -[NSObject seq] before doing anything else.
////////////////////////////////////////////////////////////////////////////////

- (id)map:(Map)map;
- (id)reduce:(Reduce)reduce seed:(id)seed;
- (id)concat:(id)tail; // -[NSObject seq] is called on tail
- (id)filter:(Predicate)predicate;

// returns true if all of the items in the sequence satisfy the predicate
- (BOOL)all:(Predicate)predicate;

// returns true if any of the items in the sequence satisfy the predicate
- (BOOL)any:(Predicate)predicate;

// calls the action for each item in the sequence
- (void)each:(Action)action;

////////////////////////////////////////////////////////////////////////////////
// the following methods will materialize the reciever
////////////////////////////////////////////////////////////////////////////////

// returns the number of items in the sequence
- (NSUInteger)size;
- (id)itemAtIndex:(NSUInteger)index;
// materializes the receiver into an NSArray.
- (NSArray *)array;

@end
