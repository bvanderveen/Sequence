#import "SequenceTests.h"
#import "Sequence.h"

@interface MockEnumerator : NSArray {
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
    position++;
    return [items objectAtIndex:position - 1];
}

- (void)dealloc {
    self.items = nil;
    [super dealloc];
}

- (NSEnumerator *)objectEnumerator {
    position = 0;
    return (NSEnumerator *)self;
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
    
    if (actualArray.count != expectedArray.count)
        STAssertTrue(NO, @"actual.count != expected.count");
    
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
    id actual = [input array];
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

- (void)testConcatSingleItemArrays {
    NSArray *head = [NSArray arrayWithObject:@"a"];
    NSArray *tail = [NSArray arrayWithObject:@"b"];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingleAndMultiItemArray {
    NSArray *head = [NSArray arrayWithObject:@"a"];
    NSArray *tail = [NSArray arrayWithObjects:@"b", @"c", @"d", nil];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatMultiAndSingleItemArray {
    NSArray *head = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *tail = [NSArray arrayWithObject:@"d"];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingles {
    NSArray *head = [@"a" seq];
    NSArray *tail = [@"b" seq];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingleAndSingleItemArray {
    NSArray *head = [@"a" seq];
    NSArray *tail = [NSArray arrayWithObject:@"b"];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingleAndMultipleItemArray {
    NSArray *head = [@"a" seq];
    NSArray *tail = [NSArray arrayWithObjects:@"b", @"c", @"d", nil];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingleItemArrayAndSingle {
    NSArray *head = [NSArray arrayWithObject:@"a"];
    NSArray *tail = [@"b" seq];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatMultiItemArrayAndSingle {
    NSArray *head = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *tail = [@"d" seq];
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatSingleAndObject {
    id head = [@"a" seq];
    id tail = @"b";
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testConcatObjectAndObject {
    id head = @"a";
    id tail = @"b";
    
    id actual = [head concat:tail];
    id expected = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilterSingle {
    id input = [@"aa" seq];
    id actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
    NSArray *expected = [NSArray arrayWithObject:@"aa"];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilterSingleNegative {
    id input = [@"aaa" seq];
    id actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
    id expected = [Seq empty];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilterSingleItemArray {
    id input = [NSArray arrayWithObject:@"aa"];
    id actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
    NSArray *expected = [NSArray arrayWithObject:@"aa"];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilterSingleItemArrayNegative {
    id input = [NSArray arrayWithObject:@"aaa"];
    id actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
    id expected = [Seq empty];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testFilter {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"aa", @"aaa", @"b", @"bb", @"cc", @"ccc", nil];
    id actual = [input filter:^ BOOL (id i) { return [i length] == 2; }];
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

- (void)testAllShortcircuits {
    NSArray *input = [NSArray arrayWithObjects:@"a", [NSNull null], @"b", @"c", nil];
    MockEnumerator *e = [[MockEnumerator new] autorelease];
    e.items = input;
    
    BOOL actualResult = [e all:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
    BOOL expectedResult = NO;
    
    NSUInteger actualPosition = e.position;
    NSUInteger expectedPosition = 2;
    
    STAssertEquals(actualResult, expectedResult, @"all are not NSString");
    STAssertEquals(actualPosition, expectedPosition, @"enumerator shortcircuited");
}

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

- (void)testAnyShortcircuits {
    NSArray *input = [NSArray arrayWithObjects:[NSNull null], [NSNull null], @"c", [NSNull null], [NSNull null], nil];
    MockEnumerator *e = [[MockEnumerator new] autorelease];
    e.items = input;
    
    BOOL actualResult = [e any:^ BOOL (id i) { return [i isKindOfClass:[NSString class]]; }];
    BOOL expectedResult = YES;
    
    NSUInteger actualPosition = e.position;
    NSUInteger expectedPosition = 3;
    
    STAssertEquals(actualResult, expectedResult, @"all are not NSString");
    STAssertEquals(actualPosition, expectedPosition, @"enumerator shortcircuited");
}

- (void)testLengthZero {
    id input = [[NSArray array] seq];
    
    NSUInteger actual = [input length];
    NSUInteger expected = 0;
    
    STAssertEquals(actual, expected, @"length is correct");
}

- (void)testLengthSingleItemArray {
    id input = [[NSArray arrayWithObjects:@"a", nil] seq];
    
    NSUInteger actual = [input length];
    NSUInteger expected = 1;
    
    STAssertEquals(actual, expected, @"length is correct");
}

- (void)testLengthSingleItem {
    id input = [@"a" seq];
    
    NSUInteger actual = [input length];
    NSUInteger expected = 1;
    
    STAssertEquals(actual, expected, @"length is correct");
}

- (void)testLength {
    NSArray *input = [NSArray arrayWithObjects:@"a", @"a", @"a", @"a", @"a", nil];
    
    NSUInteger actual = [input length];
    NSUInteger expected = 5;
    
    STAssertEquals(actual, expected, @"length is correct");
}

- (void)testRangePositive {
    id actual = [Seq rangeWithStart:0 end:2];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:2], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testRangeAcrossZero {
    id actual = [Seq rangeWithStart:-1 end:1];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:-1], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testRangeNegative {
    id actual = [Seq rangeWithStart:-2 end:0];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:-2], [NSNumber numberWithInteger:-1], [NSNumber numberWithInteger:0], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testRangeBackwardsPositive {
    id actual = [Seq rangeWithStart:2 end:0];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:2], [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testRangeBackwardsAcrossZero {
    id actual = [Seq rangeWithStart:1 end:-1];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:-1], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

- (void)testRangeBackwardsNegative {
    id actual = [Seq rangeWithStart:0 end:-2];
    id expected = [NSArray arrayWithObjects:[NSNumber numberWithInteger:0], [NSNumber numberWithInteger:-1], [NSNumber numberWithInteger:-2], nil];
    
    [self assertActual:actual equalsExpected:expected];
}

@end
