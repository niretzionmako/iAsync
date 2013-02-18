#import "JFFCallbacksBlocksHolder.h"

@implementation JFFCallbacksBlocksHolder

- (id)initWithOnProgressBlock:(JFFAsyncOperationProgressHandler)onProgressBlock
                onCancelBlock:(JFFCancelAsyncOperationHandler)onCancelBlock
             didLoadDataBlock:(JFFDidFinishAsyncOperationHandler)didLoadDataBlock
{
    self = [ super init ];

    if (self) {
        
        self.onProgressBlock  = onProgressBlock;
        self.onCancelBlock    = onCancelBlock;
        self.didLoadDataBlock = didLoadDataBlock;
    }

    return self;
}

@end
