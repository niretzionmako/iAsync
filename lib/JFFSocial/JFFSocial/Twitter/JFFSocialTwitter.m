#import "JFFSocialTwitter.h"

#import "JFFAsyncTwitterRequest.h"
#import "JFFAsyncTwitterAccessRequest.h"

#import "JFFAsyncTwitterCreateAccount.h"
#import "JFFNoTwitterAccountsError.h"
#import "JFFSocialAsyncUtils.h"
#import "AsyncAnalyzers.h"

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

#define DEFAULT_SEARCH_RADIUS 100.0f

static JFFAsyncOperation tritterAccountsLoader()
{
    JFFAsyncOperation accountsLoader = ^JFFCancelAsyncOperation(JFFAsyncOperationProgressHandler progressCallback,
                                                                JFFCancelAsyncOperationHandler cancelCallback,
                                                                JFFDidFinishAsyncOperationHandler doneCallback)
    {
        JFFAnalyzer twitterAccounts = ^id(id result, NSError **error)
        {
            ACAccountStore *accountStore = [ACAccountStore new];

            ACAccountType *type = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

            NSArray *accounts = [accountStore accountsWithAccountType:type];

            if ([accounts count]>0)
                return @[accountStore, accounts];

            if (error)
                *error = [JFFNoTwitterAccountsError new];
            return nil;
        };

        NSArray *accounts = twitterAccounts(nil, NULL);

        JFFAsyncOperation loader;

        if ([accounts count] > 0)
        {
            loader = asyncOperationWithResult(accounts);
        }
        else
        {
            loader = bindSequenceOfAsyncOperations(jffCreateTwitterAccountLoader(),
                                                   asyncOperationBinderWithAnalyzer(twitterAccounts),
                                                   nil
                                                   );
        }

        return loader(progressCallback, cancelCallback, doneCallback);
    };

    return sequenceOfAsyncOperations(jffTwitterAccessRequestLoader(),
                                     accountsLoader,
                                     nil
                                     );;

}

@implementation JFFSocialTwitter

#pragma mark - MMSocialServiceProtocol

/*- (BOOL)isAuthorized
{
    return [TWTweetComposeViewController canSendTweet];
}*/

#pragma mark - JFF Async operations

#pragma mark Users request

+ (JFFAsyncOperation)generalTwitterApiDataLoaderWithURLString:(NSString *)urlString
                                                   parameters:(NSDictionary *)parameters
                                                requestMethod:(TWRequestMethod)requestMethod
                                                 ayncAnalizer:(JFFAsyncOperationBinder)ayncAnalizer
{
    JFFAsyncOperationBinder requestBinder = ^JFFAsyncOperation(NSArray *accountStroreAndAccounts)
    {
        TWRequest *request = [[TWRequest alloc] initWithURL:[urlString toURL]
                                                 parameters:parameters
                                              requestMethod:requestMethod];

        request.account = accountStroreAndAccounts[1][0];

        JFFAsyncOperation requestOperation = jffTwitterRequest(request);

        return requestOperation;
    };

    JFFAsyncOperation loaderOperation = bindSequenceOfAsyncOperations(tritterAccountsLoader(),
                                                                      requestBinder,
                                                                      nil);

    return bindSequenceOfAsyncOperations(loaderOperation,
                                         twitterResponseToNSData(),
                                         asyncJsonDataAnalizer(),
                                         ayncAnalizer,
                                         nil);
}

+ (JFFAsyncOperation)usersNearbyCoordinatesLantitude:(double)lantitude longitude:(double)longitude
{
    static NSString *geocodeFormat = @"%f,%f,100mi";

    NSDictionary *params = @{
    @"q"                : @"",
    @"geocode"          : [[NSString alloc]initWithFormat:geocodeFormat, lantitude, longitude],
    @"count"            : @"100",
    @"include_entities" : @"true",
    @"result_type"      : @"recent",
    };

    return [self generalTwitterApiDataLoaderWithURLString:@"https://api.twitter.com/1.1/search/tweets.json"
                                               parameters:params
                                            requestMethod:TWRequestMethodGET
                                             ayncAnalizer:asyncJSONObjectToTwitterTweets()];
}

+ (JFFAsyncOperation)followersLoader
{
    JFFAsyncOperation followersIds = [self generalTwitterApiDataLoaderWithURLString:@"https://api.twitter.com/1.1/followers/ids.json"
                                                                         parameters:nil
                                                                      requestMethod:TWRequestMethodGET
                                                                       ayncAnalizer:jsonObjectToTwitterUsersIds()];

    JFFAsyncOperationBinder usersForIds = ^JFFAsyncOperation(NSArray *ids)
    {
        NSDictionary *params = @{
        @"user_id" : [ids componentsJoinedByString:@","],
        };

        JFFAsyncOperation result = [self generalTwitterApiDataLoaderWithURLString:@"https://api.twitter.com/1.1/users/lookup.json"
                                                                       parameters:params
                                                                    requestMethod:TWRequestMethodGET
                                                                     ayncAnalizer:asyncJSONObjectToTwitterUsers()];
        return result;
    };

    return bindSequenceOfAsyncOperations(followersIds, usersForIds, nil);
}

+ (JFFAsyncOperation)sendMessage:(NSString *)message
                toFollowerWithId:(NSString *)userId
{
    NSDictionary *params = @{
    @"text"    : message,
    @"user_id" : userId,
    };

    JFFAsyncOperation result = [self generalTwitterApiDataLoaderWithURLString:@"https://api.twitter.com/1.1/direct_messages/new.json"
                                                                   parameters:params
                                                                requestMethod:TWRequestMethodPOST
                                                                 ayncAnalizer:asyncJSONObjectToDirectTweet()];
    return result;
}

@end
