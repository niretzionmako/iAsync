#import "JFFNetworkAsyncOperation.h"

#import "JFFURLConnectionParams.h"
#import "JNConnectionsFactory.h"
#import "JNUrlConnection.h"

#import "JFFNetworkResponseDataCallback.h"
#import "JFFNetworkUploadProgressCallback.h"

#import <JFFNetwork/JNUrlResponse.h>

@implementation JFFNetworkAsyncOperation

- (void)asyncOperationWithResultHandler:(JFFAsyncOperationInterfaceResultHandler)handler
                          cancelHandler:(JFFAsyncOperationInterfaceCancelHandler)cancelHandler
                        progressHandler:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    NSParameterAssert(handler );
    NSParameterAssert(progress);
    
    {
        JNConnectionsFactory *factory =
        [[JNConnectionsFactory alloc] initWithURLConnectionParams:self.params];
        
        self.connection = [factory createConnection];
    }
    
    self.connection.shouldAcceptCertificateBlock = self.params.certificateCallback;
    
    __unsafe_unretained JFFNetworkAsyncOperation *unretainedSelf = self;
    
    progress = [progress copy];
    self.connection.didReceiveDataBlock = ^(NSData *dataChunk) {
        
        JFFNetworkResponseDataCallback *progressData = [JFFNetworkResponseDataCallback new];
        progressData.dataChunk = dataChunk;
        progress(progressData);
    };
    
    self.connection.didUploadDataBlock = ^(NSNumber *progressNum) {
        
        JFFNetworkUploadProgressCallback *uploadProgress = [JFFNetworkUploadProgressCallback new];
        uploadProgress.progress = progressNum;
        uploadProgress.params   = unretainedSelf.params;
        progress(uploadProgress);
    };
    
    __block id resultHolder;
    
    JFFNetworkErrorTransformer errorTransformer = _errorTransformer;
    
    handler = [handler copy];
    JFFDidFinishLoadingHandler finish = [^(NSError *error) {
        
        if (error) {
            
            handler(nil, errorTransformer?errorTransformer(error):error);
            return;
        }
        
        handler(resultHolder, nil);
        
    } copy];
    
    finish = [finish copy];
    self.connection.didFinishLoadingBlock = finish;
    
    self.connection.didReceiveResponseBlock = ^void(id<JNUrlResponse> response) {
        
        if (!unretainedSelf->_responseAnalyzer) {
            resultHolder = response;
            return;
        }
        
        NSError *error;
        resultHolder = unretainedSelf->_responseAnalyzer(response, &error);
        
        if (error) {
            [unretainedSelf forceCancel];
            finish(error);
        }
    };
    
    [self.connection start];
}

- (void)forceCancel
{
    [self cancel:YES];
}

- (void)cancel:(BOOL)canceled
{
    self.connection.didReceiveDataBlock          = nil;
    self.connection.didFinishLoadingBlock        = nil;
    self.connection.didReceiveResponseBlock      = nil;
    self.connection.didUploadDataBlock           = nil;
    self.connection.shouldAcceptCertificateBlock = nil;
    
    //TODO maybe always cancel?
    if (canceled) {
        [self.connection cancel];
        self.connection = nil;
    }
}

@end
