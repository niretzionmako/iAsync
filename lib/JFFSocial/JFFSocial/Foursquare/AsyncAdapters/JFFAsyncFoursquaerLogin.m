#import "JFFAsyncFoursquaerLogin.h"

#import <JFFUI/Categories/UIApplication+OpenApplicationAsyncOp.h>

#import "JFFFoursquareSessionStorage.h"

@interface JFFAsyncFoursquaerLogin : NSObject <JFFAsyncOperationInterface>

@property (copy, nonatomic) JFFCancelAsyncOperation cancelOperation;

@end

@implementation JFFAsyncFoursquaerLogin

- (void)asyncOperationWithResultHandler:(JFFAsyncOperationInterfaceResultHandler)handler
                          cancelHandler:(JFFAsyncOperationInterfaceCancelHandler)cancelHandler
                        progressHandler:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    handler = [handler copy];
    
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *url = [[JFFFoursquareSessionStorage authURLString] toURL];
    JFFAsyncOperation loader = [application asyncOperationWithApplicationURL:url];
    
    loader(nil, nil, ^(id result, NSError *error) {
        handler(result, error);
    });
}

- (void)cancel:(BOOL)canceled
{
    if (self.cancelOperation) {
        self.cancelOperation (canceled);
    }
}

@end


JFFAsyncOperation jffFoursquareLoginLoader ()
{
    JFFAsyncOperationInstanceBuilder factory = ^id< JFFAsyncOperationInterface >() {
        return [JFFAsyncFoursquaerLogin new];
    };
    
    return buildAsyncOperationWithAdapterFactory(factory);
}