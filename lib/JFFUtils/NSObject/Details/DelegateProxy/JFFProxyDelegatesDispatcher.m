#import "JFFProxyDelegatesDispatcher.h"

#import "JFFMutableAssignArray.h"

#import "NSArray+BlocksAdditions.h"

@implementation JFFProxyDelegatesDispatcher
{
    JFFMutableAssignArray *_delegates;
    id _realDelegate;
}

+ (instancetype)newProxyDelegatesDispatcherWithRealDelegate:(id)realDelegate
                                                  delegates:(JFFMutableAssignArray *)delegates
{
    JFFProxyDelegatesDispatcher *result = [JFFProxyDelegatesDispatcher new];
    
    if (result) {
        
        result->_delegates    = delegates;
        result->_realDelegate = realDelegate;
    }
    
    return result;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL selector = [invocation selector];
    
    [[_delegates array] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:selector])
            [invocation invokeWithTarget:obj];
    }];
    
    if ([_realDelegate respondsToSelector:selector])
        [invocation invokeWithTarget:_realDelegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    __block NSMethodSignature *result;
    [[_delegates array] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        result = [obj methodSignatureForSelector:selector];
        if (result)
            *stop = YES;
    }];
    
    result = result?:[_realDelegate methodSignatureForSelector:selector];
    
    return result;
}

@end
