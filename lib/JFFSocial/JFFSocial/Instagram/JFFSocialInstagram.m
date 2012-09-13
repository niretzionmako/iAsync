#import "JFFSocialInstagram.h"

#import "JFFInstagramCredentials.h"
#import "JFFInstagramMediaItem.h"
#import "JFFInstagramAuthedAccount.h"

#import "JFFSocialAsyncUtils.h"
#import "JFFInstagramResponseError.h"
#import "JFFInvalidInstagramResponseURLError.h"

#import "JFFSocialInstagramApi.h"

#import "JFFInstagramJSONDataAnalyzers.h"

static NSString *globalAccessToken;

@implementation JFFSocialInstagram

+ (JFFAsyncOperation)userLoaderForForUserId:(NSString *)userId
                                accessToken:(NSString *)accessToken
{
    JFFAsyncOperation loader = userDataLoader(userId, accessToken);

    return bindSequenceOfAsyncOperations(loader, jsonDataToOneAccountBinder(), nil);
}

+ (JFFAsyncOperation)instagramAccessTokenLoaderForCredentials:(JFFInstagramCredentials *)redentials
{
    if (globalAccessToken)
    {
        return asyncOperationWithResult(globalAccessToken);
    }

    JFFAsyncOperation accountLoader = [self authedUserLoaderWithCredentials:redentials];

    JFFAsyncOperationBinder saveAccessTokenBinder = ^JFFAsyncOperation(JFFInstagramAuthedAccount *account)
    {
        globalAccessToken = account.instagramAccessToken;
        return asyncOperationWithResult(globalAccessToken);
    };

    return bindSequenceOfAsyncOperations(accountLoader, saveAccessTokenBinder, nil);
}

+ (JFFAsyncOperation)authedUserLoaderWithCredentials:(JFFInstagramCredentials *)redentials
{
    JFFAsyncOperation oAuthUrlLoader = codeURLLoader(redentials.redirectURI, redentials.clientId);

    JFFAsyncOperationBinder urlToCodeBinder = ^JFFAsyncOperation(NSURL *url)
    {
        NSDictionary *params = [[url query]dictionaryFromQueryComponents];
        NSArray* codeParams = params[@"code"];

        if ([codeParams count]==0)
        {
            JFFInvalidInstagramResponseURLError *error = [JFFInvalidInstagramResponseURLError new];
            error.url = url;
            return asyncOperationWithError(error);
        }

        NSString *code = codeParams[0];
        return asyncOperationWithResult(code);
    };

    JFFAsyncOperationBinder userDataBinder = ^JFFAsyncOperation(NSString *code)
    {
        return authedUserDataLoader(redentials.redirectURI,
                                    redentials.clientId,
                                    redentials.clientSecret,
                                    code
                                    );
    };

    return bindSequenceOfAsyncOperations(oAuthUrlLoader,
                                         urlToCodeBinder,
                                         userDataBinder,
                                         jsonDataToAuthedAccountBinder(),
                                         nil );
}

+ (JFFAsyncOperation)followedByLoaderForUserId:(NSString *)userId
                                   accessToken:(NSString *)accessToken
{
    JFFAsyncOperation loader = followersJSONDataLoader(userId,
                                                       accessToken
                                                       );

    return bindSequenceOfAsyncOperations(loader, jsonDataToAccountsBinder(), nil);
}

+ (JFFAsyncOperation)followedByLoaderWithCredentials:(JFFInstagramCredentials *)credentials
{
    JFFAsyncOperation userLoader = [self instagramAccessTokenLoaderForCredentials:credentials];

    JFFAsyncOperationBinder userRelatedDataBinder = ^JFFAsyncOperation(NSString *accessToken)
    {
        return [self followedByLoaderForUserId:@"self"
                                   accessToken:accessToken];
    };

    return bindSequenceOfAsyncOperations(userLoader,
                                         userRelatedDataBinder,
                                         nil );
}

+ (JFFAsyncOperation)recentMediaItemsLoaderForUserId:(NSString *)userId
                                         accessToken:(NSString *)accessToken
{
    JFFAsyncOperation loader = mediaItemsDataLoader(userId, accessToken);

    return bindSequenceOfAsyncOperations(loader,
                                         jsonDataToMediaItems(),
                                         nil);
}

+ (JFFAsyncOperation)commentMediaItemLoaderWithId:(NSString *)mediaItemId
                                          comment:(NSString *)comment
                                      accessToken:(NSString *)accessToken
{
    JFFAsyncOperation loader = commentMediaItemDataLoader(mediaItemId, comment, accessToken);

    return bindSequenceOfAsyncOperations(loader,
                                         jsonDataToComment(),
                                         nil);
}

+ (JFFAsyncOperation)notifyUsersWithLoader:(JFFAsyncOperation)usersLoader
                                   message:(NSString *)message
                               accessToken:(NSString *)accessToken
{
    JFFAsyncOperationBinder recentMediaItemsBinder = ^JFFAsyncOperation(NSArray *accounts)
    {
        NSArray *mediaItemsLoaders = [accounts map:^id(JFFInstagramAccount *account)
        {
            return [self recentMediaItemsLoaderForUserId:account.instagramAccountId
                                             accessToken:accessToken];
        }];

        return groupOfAsyncOperationsArray(mediaItemsLoaders);
    };

    JFFAsyncOperationBinder selectFirstMediaItemsBinder = ^JFFAsyncOperation(NSArray *arrayOfArrayMediaItems)
    {
        NSArray *result = [arrayOfArrayMediaItems forceMap:^id(NSArray *mediaItems)
        {
            return [mediaItems count]>0?mediaItems[0]:nil;
        }];

        return asyncOperationWithResult(result);
    };

    JFFAsyncOperationBinder commentEachMediaItemsBinder = ^JFFAsyncOperation(NSArray *mediaItems)
    {
        NSArray *commentMediaItemsLoaders = [mediaItems map:^id(JFFInstagramMediaItem *mediaItem)
        {
            return [self commentMediaItemLoaderWithId:mediaItem.mediaItemId
                                              comment:message
                                          accessToken:accessToken];
        }];

        return groupOfAsyncOperationsArray(commentMediaItemsLoaders);
    };

    return bindSequenceOfAsyncOperations(usersLoader,
                                         recentMediaItemsBinder,
                                         selectFirstMediaItemsBinder,
                                         commentEachMediaItemsBinder,
                                         nil);
}

+ (JFFAsyncOperation)notifyUsersFollowersWithId:(NSString *)userId
                                        message:(NSString *)message
                                    accessToken:(NSString *)accessToken
{
    JFFAsyncOperation usersLoader = [self followedByLoaderForUserId:userId
                                                        accessToken:accessToken];

    return [self notifyUsersWithLoader:usersLoader
                               message:message
                           accessToken:accessToken];
}

+ (JFFAsyncOperation)notifyUsersFollowersWithCredentials:(JFFInstagramCredentials *)credentials
                                                 message:(NSString *)message
{
    JFFAsyncOperation accessTokenLoader = [self instagramAccessTokenLoaderForCredentials:credentials];

    JFFAsyncOperationBinder notifyBinder = ^JFFAsyncOperation(NSString *accessToken)
    {
        return [self notifyUsersFollowersWithId:@"self"
                                        message:message
                                    accessToken:accessToken];
    };

    return bindSequenceOfAsyncOperations(accessTokenLoader,
                                         notifyBinder,
                                         nil);
}

+ (JFFAsyncOperation)notifyUsersWithCredentials:(JFFInstagramCredentials *)credentials
                                       usersIds:(NSArray *)usersIds
                                        message:(NSString *)message
{
    JFFAsyncOperation accessTokenLoader = [self instagramAccessTokenLoaderForCredentials:credentials];
    
    JFFAsyncOperationBinder notifyBinder = ^JFFAsyncOperation(NSString *accessToken)
    {
        NSArray *usersLoaders = [usersIds map:^id(NSString *userId)
        {
            return [self userLoaderForForUserId:userId
                                    accessToken:accessToken];
        }];

        JFFAsyncOperation usersLoader = groupOfAsyncOperationsArray(usersLoaders);

        return [self notifyUsersWithLoader:usersLoader
                                   message:message
                               accessToken:accessToken];
    };

    return bindSequenceOfAsyncOperations(accessTokenLoader,
                                         notifyBinder,
                                         nil);
}

@end
