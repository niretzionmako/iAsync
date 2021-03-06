#import "JFFAddressBook.h"

#import <AddressBook/AddressBook.h>

@implementation JFFAddressBook
{
    ABAddressBookRef _rawBook;
}

- (void)dealloc
{
    CFRelease(_rawBook);
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithRawBook:(ABAddressBookRef)rawBook_
{
    NSParameterAssert(NULL != rawBook_);
    
    self = [super init];
    if (nil == self) {
        return nil;
    }
    
    _rawBook = rawBook_;
    
    return self;
}

- (BOOL)removeAllContactsWithError:(NSError **)error
{
    ABAddressBookRef rawBook_ = self.rawBook;
    CFErrorRef rawError_ = NULL;
    NSArray* contacts_ = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(rawBook_);
    
    for ( id record_ in contacts_ )
    {
        ABRecordRef rawRecord_ = (__bridge ABRecordRef)record_;
        ABAddressBookRemoveRecord( rawBook_, rawRecord_, &rawError_ );
        if ( NULL != rawError_ )
        {
            [ (__bridge NSError*)rawError_ setToPointer:error];
            return NO;
        }
    }
    
    ABAddressBookSave( rawBook_, &rawError_ );
    if ( NULL != rawError_ ) {
        [ (__bridge NSError*)rawError_ setToPointer:error];
        return NO;
    }
    
    return YES;
}

@end
