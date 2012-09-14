#import "NSArray+FqCheckinsAPIParser.h"

#import "NSDictionary+FqAPIresponseParser.h"
#import "FoursquareCheckinsModel+APIParser.h"

#import "JFFFoursquaerAPIInvalidresponseError.h"

@implementation NSArray (FqCheckinsAPIParser)


+ (NSArray *)fqCheckinsWithDict:(NSDictionary *)response error:(NSError **)outError
{
    NSError *error = nil;
    
    NSArray *friendsArray = [[response dictionaryForKey:@"checkins"] arrayForKey:@"items"];
    
    if (friendsArray) {
        friendsArray = [friendsArray map:^id(NSDictionary *object, NSError *__autoreleasing *outError) {
            
            NSError *error = nil;
            FoursquareCheckinsModel *checkinModel = [FoursquareCheckinsModel fqCheckinModelWithDict:object error:&error];
            [error setToPointer:outError];
            return checkinModel;
            
        } error:&error];
    }
    else
    {
        [[JFFFoursquaerAPIInvalidresponseError new] setToPointer:outError];
    }
    
    return friendsArray;
}
/*

response: {
checkins: {
count: 1
items: [
    ...
        ]
}
}
*/
@end
