//
//  EBSmartURLConnection.m
//  

#import "EBSmartURLConnection.h"
#import <JSONKit.h>

@implementation EBSmartURLConnection
@synthesize data = _data, response = _response;

- (id)initWithRequest: (NSURLRequest *)request 
             delegate: (id)delegate 
        callbackBlock: (EBVKAPICallbackBlock)callbackBlock
       responseFormat: (enum EBVKAPIResponseFormat)format
{
    if (!callbackBlock) return (self=nil, self);
    if ((self = [super initWithRequest: request delegate: delegate])) {
        _callback_block = Block_copy(callbackBlock);
        _data = nil;
        _response = nil;
        _response_format = format;
    
        [self start];
    }
    return self;
}

- (void)dealloc
{
    Block_release(_callback_block);
    if (_data)     [_data release];
    if (_response) [_response release];
    
    [super dealloc];
}

#pragma mark Callbacks API

/* [FIXED]:
   It was a bad idea to release a |_callback_block| on the end of these methods. 
   The more suitable place for this is the -dealloc method, I think. 
*/
   
- (void)performCallbackBlock
{
    if ( !(_callback_block && _data)) {
        return;
    }
    @synchronized (self) {
        [[self class] performCallbackBlock: _callback_block 
                                      data: _data 
                                       raw: (_response_format == kEBRawXMLFormat)];
    } 
}

- (void)performCallbackBlockWithResponse:(EBVKAPIResponse *)response
{
    if ( !(_callback_block && response)) {
        return;
    }
    @synchronized (self) {
        _callback_block(response);
    }
    
}

- (void)performCallbackBlockWithError:(NSError*)error
{
    if ( !(_callback_block && error)) {
        return;
    }
    @synchronized (self) {
        _callback_block([EBVKAPIResponse responseWithSDKError: error]);
    }
}


+ (void)performCallbackBlock:(EBVKAPICallbackBlock)callback data:(NSData *)data raw:(BOOL)raw
{
    if (raw) {
        callback([EBVKAPIResponse responseWithRawData: data]);
    } else {
        callback([EBVKAPIResponse responseWithObject: 
                                         [[JSONDecoder decoder] parseJSONData: data]]);
    }
}
 

#pragma mark Deprecated

- (id)init
{
    return (nil);
}
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    return (nil);
}
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    return (nil);
}
@end
