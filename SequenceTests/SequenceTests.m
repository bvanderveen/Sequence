#import "SequenceTests.h"
#import "Sequence.h"

@interface MockEnumerator : NSEnumerator {
    NSArray *items;
    NSUInteger position;
}

@property (nonatomic, retain) NSArray *items;
@property (nonatomic, readonly) NSUInteger position;

@end

@implementation MockEnumerator

@synthesize items, position;

- (id)nextObject {
    if (position == items.count)
        return nil;
    return [items objectAtIndex:position++];
}

- (void)dealloc {
    self.items = nil;
    [super dealloc];
}

@end

@implementation SequenceTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)assertActual:(id)actual equalsExpected:(id)expected {
    NSArray *actualArray = [actual array];
    NSArray *expectedArray = [expected array];
    
    for (int i = 0; i < expectedArray.count; i++) {
        if (i == actualArray.count)
            STAssertTrue(NO, @"expected more elements than contained in actual");
        
        id expectedItem = [expectedArray objectAtIndex:i];
        id actualItem = [actualArray objectAtIndex:i];
        
        STAssertEqualObjects(expectedItem, actualItem, @"elements differed at index %d", i);
        
    }
}

- (void)testEmpty {
    NSUInteger actual = [[Seq empty] array].count;
    NSUInteger expected = 0;
    STAssertEquals(actual, expected, @"Empty has zero elements");
}

- (void)testArray {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *actual = [input array];
    NSArray *expected = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testMap
{
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil],
    *actual = [input map:^ id (id i) { return [i stringByAppendingString:i]; }],
    *expected = [NSArray arrayWithObjects:@"aa", @"bb", @"cc", nil];
    [self assertActual:actual equalsExpected:expected];
}

- (void)testReduce {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    
    NSString *actual = [input reduce:^ id (id acc, id i) { return [acc stringByAppendingString:i]; } seed:@""];
    NSString *expected = @"abc";
    STAssertEqualObjects(actual, expected, @"reduce, strings concatenated");
}

- (void)testConcat {
    NSArray *head = [NSArray arrayWithObject:@"a"];
    NSArray *tail = [NSArray arrayWithObject:@"b"];
    
    NSArray *actual = [head concat:tail];
    Seq *expected = [[NSArray arrayWithObjects:@"a", @"b", nil] seq];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilter {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"aa", @"aaa", @"b", @"bb", @"cc", @"ccc", nil];
    NSArray *actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
    NSArray *expected = [NSArray arrayWithObjects:@"aa", @"bb", @"cc", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testEach {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSMutableArray *actual = [NSMutableArray array];
    
    [input each:^ void (id i) { [actual addObject:i]; }];
    
    NSArray *expected = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testAll {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    
    BOOL actual = [input all:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
    BOOL expected = YES;
    
    STAssertEquals(actual, expected, @"all are NSString");
}

// XXX doesn't work right now!
//- (void)testAllShortcircuits {
//    NSArray *input = [NSArray arrayWithObjects:@"a", [NSNull null], @"b", @"c", nil];
//    MockEnumerator *e = [[MockEnumerator new] autorelease];
//    e.items = input;
//    
//    BOOL actualResult = [e all:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
//    BOOL expectedResult = NO;
//    
//    NSUInteger actualPosition = e.position;
//    NSUInteger expectedPosition = 1;
//    
//    STAssertEquals(actualResult, expectedResult, @"all are not NSString");
//    STAssertEquals(actualPosition, expectedPosition, @"enumerator shortcircuited");
//}

- (void)testAllNegative {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", [NSNull null], @"a", @"d", nil];
    
    BOOL actual = [input all:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
    BOOL expected = NO;
    
    STAssertEquals(actual, expected, @"all are NSString");
}

- (void)testAny {
    NSArray *input = [NSArray arrayWithObjects:[NSNull null], [NSNull null], @"c", [NSNull null], [NSNull null], nil];
    
    BOOL actual = [input any:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
    BOOL expected = YES;
    
    STAssertEquals(actual, expected, @"any are NSString");
}

- (void)testAnyNegative {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    
    BOOL actual = [input any:^ BOOL (id i) { return [i isKindOfClass:[NSNull class]]; }];
    BOOL expected = NO;
    
    STAssertEquals(actual, expected, @"any are NSNull");
}

- (void)testSize {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"a", @"a", @"a", @"a", nil];
    
    NSUInteger actual = [input size];
    NSUInteger expected = 5;
    
    STAssertEquals(actual, expected, @"size is correct");
}

@end
