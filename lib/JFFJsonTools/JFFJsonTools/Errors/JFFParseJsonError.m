#import "JFFParseJsonError.h"

@implementation JFFParseJsonError

- (id)init
{
    return [self initWithDescription:NSLocalizedString(@"PARSE_JSON_ERROR", nil)];
}

- (id)copyWithZone:(NSZone *)zone
{
    JFFParseJsonError *copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        copy->_nativeError = [self->_nativeError copyWithZone:zone];
        copy->_data        = [self->_data        copyWithZone:zone];
        copy->_context     = [self->_context     copyWithZone:zone];
    }
    
    return copy;
}

- (void)writeErrorWithJFFLogger
{
    [JFFLogger logErrorWithFormat:@"%@ context: %@ data: %@", [self localizedDescription], _context, [_data toString]];
}

@end
