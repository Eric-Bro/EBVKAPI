//
//  EBVKAPIRequest.h
//

#import <Foundation/Foundation.h>

#import "EBVKAPIToken.h"
#import "EBVKAPIResponse.h"

@class JSONDecoder;
@class EBVKAPIToken;

/* Set your own application's name and vesion */
#define kVKAPIApplicationName    @"EBVKAPI"
#define kVKAPIApplicationVersion @"0.4"
/* The rule a User-Agent string'll be generated with */
#define kVKAPIUserAgentString [NSString stringWithFormat: @"%@ (v.%@) via EBVKAPI", kVKAPIApplicationName, kVKAPIApplicationVersion]

enum EBVKAPIResponseFormat{
    kEBRawXMLFormat     = 0x1,
    kEBPreparsedFormat  = 0x2
}EBVKAPIResponseFormat;

enum EBVKAPIRequestType {
    kEBAsynchronousRequestType = 0x1,
    kEBSynchronousRequestType = 0x0
}EBVKAPIRequestType;

typedef void (^EBVKAPICallbackBlock)(EBVKAPIResponse *response);

@interface EBVKAPIRequest : NSObject <NSConnectionDelegate>
{
 @public
    NSString *_method_name;
    NSMutableDictionary *_method_params;
    enum EBVKAPIResponseFormat _method_response_format;
    enum EBVKAPIRequestType _request_type;
 @protected
    EBVKAPICallbackBlock _callback_block;
    NSOperationQueue *_queue;
    NSError *_last_recieved_error;
    id _debug_value;
}
@property (readwrite, copy) NSString *methodName;
@property (readwrite) enum EBVKAPIResponseFormat format;
@property (readonly, retain) NSError *lastReceivedError;

- (id)initWithMethodName: (NSString *)name parameters: (NSDictionary *)params responseFormat: (enum EBVKAPIResponseFormat)response_format;

#if NS_BLOCKS_AVAILABLE
- (BOOL)sendRequestWithToken: (EBVKAPIToken *)token asynchronous:(BOOL)asynchronous callbackBlock: (EBVKAPICallbackBlock)a_callback_block;
#endif
/* Synchronous only request for non-block-based API */
- (EBVKAPIResponse*)sendRequestWithToken:(EBVKAPIToken *)token;

- (NSDictionary *)parameters;
- (void)setParameters:(NSDictionary *)parameters;
- (void)setParameterValue:(NSString *)parameter forKey:(NSString *)key;

- (NSInteger)operationsQuantity;



#pragma mark 
#pragma mark Presets for most common operations

/* Music */
+ (id)audioSearchRequestWithQuery:(NSString *)quere tracksCount:(NSInteger)count offset: (NSInteger)offset sortByDate:(BOOL)sortByDate lyrics:(BOOL)lyrics;
+ (id)audioUploadRequestWithFile:(NSString  *)fullFilePath;

/* Video */
+ (id)videoSearchRequestWithQuery:(NSString *)query tracksCount:(NSInteger)count offset: (NSInteger)offset sortByDate:(BOOL)sortByDate lyrics:(BOOL)lyrics shouldBeHD:(BOOL)hd;
+ (id)videoUploadRequestWithFile:(NSString *)fullPath;

@end
