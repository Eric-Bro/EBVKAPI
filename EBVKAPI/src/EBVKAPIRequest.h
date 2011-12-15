//
//  EBVKAPIRequest.h
//

#import <Foundation/Foundation.h>

#import "EBVKAPIToken.h"
#import "EBVKAPIResponse.h"

@class JSONDecoder;
@class EBVKAPIToken;

/* Set your own application's name and vesion */
#define kVKAPIApplicationName    @"my_test_app"
#define kVKAPIApplicationVersion @"0.4"
/* The rule a User-Agent string'll be generated with */
#define kVKAPIUserAgentString [NSString stringWithFormat: @"%@ (v.%@) via EBVKAPI", kVKAPIApplicationName, kVKAPIApplicationVersion]

enum EBVKAPIResponseFormat{
    EBRawXMLFormat     = 0x1,
    EBJSONFormat       = 0x2
}EBVKAPIResponseFormat;

enum EBVKAPIRequestType {
    EBAsynchronousRequestType = 0x1,
    EBSynchronousRequestType = 0x0
}EBVKAPIRequestType;

typedef void (^EBVKAPICallbackBlock)(NSDictionary *server_response, NSError *error);

@interface EBVKAPIRequest : NSObject <NSURLConnectionDelegate>
{
    NSString *_method_name;
    NSMutableDictionary *_method_params;
    enum EBVKAPIResponseFormat _method_response_format;
    enum EBVKAPIRequestType _request_type;
    NSOperationQueue *_queue;
@protected
    EBVKAPICallbackBlock _callback_block;
    NSMutableData *_connection_data;
}
@property (readwrite, retain) NSMutableDictionary *parameters;
@property (readwrite, retain) NSString *methodName;
@property (readwrite) enum EBVKAPIResponseFormat format;
@property (readonly) NSInteger operationCount;

- (id)initWithMethodName: (NSString *)name parameters: (NSDictionary *)params responseFormat: (enum EBVKAPIResponseFormat)response_format;

#if NS_BLOCKS_AVAILABLE
- (BOOL)sendRequestWithToken: (EBVKAPIToken *)token asynchronous:(BOOL)asynchronous andCallbackBlock: (EBVKAPICallbackBlock)a_callback_block;
#endif
- (EBVKAPIResponse*)sendRequestWithToken:(EBVKAPIToken *)token;

/* Dealing with cookies */
/* At this case, $domain always will be the @".vk.com" */
+ (NSArray *)dumpAllCookiesForDomain:(NSString *)domain;
+ (void)setCookies:(NSArray *)new_cookies forDomain:(NSString *)domain;
+ (void)cleanUpAllCookiesForDomain: (NSString *)domain;
@end
