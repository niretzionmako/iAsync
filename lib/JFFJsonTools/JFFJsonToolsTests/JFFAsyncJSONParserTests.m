#import "JFFAsyncJSONParserTests.h"

#import "JFFAsyncJSONParser.h"

@implementation JFFAsyncJSONParserTests
{
    dispatch_semaphore_t _semaphore;
}

- (void)setUp
{
    _semaphore = dispatch_semaphore_create(0);
}

- (void)tearDown
{
    dispatch_release(_semaphore);
}

- (void)endAsync
{
    dispatch_semaphore_signal(_semaphore);
}

- (void)endTest
{
    while (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}

-(void)testParseEmtyJson
{
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    JFFAsyncOperation loader = asyncOperationJsonDataParser(data);
    
    loader(nil, nil, ^(id result, NSError *error){
        STAssertNil(error, nil);
        STAssertNotNil(result, nil);
        STAssertTrue([result isKindOfClass:[NSDictionary class]], nil);
        
        [self endAsync];
    });
    
    [self endTest];
}

@end
