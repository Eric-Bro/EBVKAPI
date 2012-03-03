//
//  EBSmartURLConnection.h
//  

#import <Foundation/Foundation.h>
#import "EBVKAPIRequest.h"

@interface EBSmartURLConnection : NSURLConnection
{
    NSMutableData *_data;
    NSHTTPURLResponse *_response;
    EBVKAPICallbackBlock _callback_block;
    enum EBVKAPIResponseFormat _response_format;
}
@property (nonatomic, copy) NSMutableData *data;
@property (nonatomic, readwrite, retain) NSHTTPURLResponse *response;

/* Deprecated super's methods */
- (id)init DEPRECATED_ATTRIBUTE;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate DEPRECATED_ATTRIBUTE;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately DEPRECATED_ATTRIBUTE;
/* --- --- --- */

- (id)initWithRequest: (NSURLRequest *)request 
             delegate: (id)delegate 
        callbackBlock: (EBVKAPICallbackBlock)callbackBlock
       responseFormat: (enum EBVKAPIResponseFormat)format;


- (void)performCallbackBlock;
/* Same as above, but uses a custom response instead of object's */
- (void)performCallbackBlockWithResponse:(EBVKAPIResponse *)response;
/* NSError object will be converted to the EBVKAPIError' object one */
- (void)performCallbackBlockWithError:(NSError *)error;


+ (void)performCallbackBlock:(EBVKAPICallbackBlock)callback data:(NSData *)data raw:(BOOL)raw;

@end
