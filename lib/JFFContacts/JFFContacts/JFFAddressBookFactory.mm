#import "JFFAddressBookFactory.h"

#import "JFFAddressBook.h"

#import "JFFAddressBookWrapperError.h"

static NSError *convertErrorType(NSError *error)
{
    if (!error)
        return nil;
    
    JFFAddressBookWrapperError *result = [JFFAddressBookWrapperError newAddressBookWrapperErrorWithNativeError:error];
    result.nativeError = error;
    return result;
}

@implementation JFFAddressBookFactory

+ (void)asyncAddressBookWithOnCreatedBlock:(JFFAddressBookOnCreated)callback
{
    NSParameterAssert(nil!=callback);
    
#ifdef kCFCoreFoundationVersionNumber_iOS_5_1
    if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) {
#endif
        [self asyncLegacyAddressBookWithOnCreatedBlock:callback];
        return;
#ifdef kCFCoreFoundationVersionNumber_iOS_5_1
    }
    
    CFErrorRef error = NULL;
    ABAddressBookRef result = ABAddressBookCreateWithOptions(0, &error);
    
    if (NULL != error) {
        NSError *retError = (__bridge NSError*)error;
        if (result)
            CFRelease(result);
        if (callback) {
            
            callback(nil, kABAuthorizationStatusNotDetermined, convertErrorType(retError));
        }
        return;
    }
    
    callback = [callback copy];
    
    ABAddressBookRequestAccessCompletionHandler onAddressBookAccess =
        ^(bool blockGranted, CFErrorRef blockError) {
            NSError *retError = (__bridge NSError *)(blockError);
            
            JFFAddressBook *bookWrapper = [[JFFAddressBook alloc] initWithRawBook:result];
            callback(bookWrapper, ::ABAddressBookGetAuthorizationStatus(), convertErrorType(retError));
        };
    
    ABAddressBookRequestAccessWithCompletion(result, onAddressBookAccess);
#endif
}

+ (void)asyncLegacyAddressBookWithOnCreatedBlock:(JFFAddressBookOnCreated)callback
{
    NSParameterAssert(nil!=callback);
    
    ABAddressBookRef result = ::ABAddressBookCreate();
    JFFAddressBook *bookWrapper = [[JFFAddressBook alloc] initWithRawBook:result];
    
    callback(bookWrapper, kABAuthorizationStatusAuthorized, nil);
}

+ (NSString *)bookStatusToString:(ABAuthorizationStatus)status
{
    if (status > kABAuthorizationStatusAuthorized) {
        return nil;
    }
    
    static NSArray *const errors =
    @[
        @"kABAuthorizationStatusNotDetermined",
        @"kABAuthorizationStatusRestricted"   ,
        @"kABAuthorizationStatusDenied"       ,
        @"kABAuthorizationStatusAuthorized"   ,
    ];
    
    return errors[status];
}

+ (void)asyncAddressBookWithSuccessBlock:(JFFAddressBookSuccessCallback)onSuccess
                           errorCallback:(JFFAddressBookErrorCallback)onFailure
{
    NSParameterAssert(nil!=onSuccess);
    NSParameterAssert(nil!=onFailure);
    
    onSuccess = [onSuccess copy];
    onFailure = [onFailure copy];
    
    [self asyncAddressBookWithOnCreatedBlock:
     ^void(JFFAddressBook *book, ABAuthorizationStatus status, NSError *error) {
         if (kABAuthorizationStatusAuthorized != status) {
             onFailure(status, error);
         } else {
             onSuccess(book);
         }
     }];
}

@end
