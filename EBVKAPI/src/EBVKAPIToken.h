//
//  EBVKAPIToken.h
//


#import <Foundation/Foundation.h>

#import "EBVKAPIRequest.h" /* For cookies work */
#import "NSString+EB.h"


enum EBVKAPITokenStatus {
    EBVKAPITokenSuccess,
    EBVKAPITokenWrongCredentials,
    EBVKAPITokenConnectionError,
    EBVKAPITokenParsingError,
    EBVKAPITokenUnknowingError,
}EBVKAPITokenStatus;

@interface EBVKAPIToken : NSObject
{
@protected
    NSString *_appid;
    NSInteger _stat;
@public
    NSString *_sid;
    NSString *_mid;
    NSString *_secret;
    NSString *_expire;
    NSArray *_cookies;
}
@property (readonly) NSString *appID;
@property (readonly) NSString *sid;
@property (readonly) NSString *mid;
@property (readonly) NSString *secret;
@property (readonly) NSString *expire;
@property (readonly) NSInteger status;
@property (readonly) NSArray *cookies;

- (id)initWithEmail:(NSString *)email password:(NSString *)password applicationID:(NSString *)app_id rights:(NSInteger)rights error:(NSError **)error;
+ (id)tokenWithEmail:(NSString *)email password:(NSString *)password applicationID:(NSString *)app_id rights:(NSInteger)rights error:(NSError **)error;
@end
