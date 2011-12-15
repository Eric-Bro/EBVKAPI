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
    withCallbackBlock: (EBVKAPICallbackBlock)callbackBlock
    andResponseFormat: (enum EBVKAPIResponseFormat)format;

- (void)runCallbackBlockWithError: (NSError*)error;

+ (void)runCustomCallbackBlock:(EBVKAPICallbackBlock)callback_block 
                      withData:(NSData *)data 
                         error:(NSError *)error
             andResponseFormat:(enum EBVKAPIResponseFormat)format;

@end
