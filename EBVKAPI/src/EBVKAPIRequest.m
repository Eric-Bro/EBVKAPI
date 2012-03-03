//
//  EBVKAPIRequest.m
//

#import "EBVKAPIRequest.h"
#import "EBVKAPICookies.h"
#import "EBSmartURLConnection.h"
#include "common_utils.h"
#import "NSString+EB.h"
#import "JSONKit.h"

#define kVKAPIVersion @"3.0"
#define EBErrorLog(x) NSLog(@"(%s : %s) : %@", __FILE__, __PRETTY_FUNCTION__, [(x) description]);

#define kEBVKAPIServer @"https://api.vk.com/api.php"

#define kEBVKAPIRequestDomain @"_ebvkapirequestdomain"

#define kEBNoDataErrorDescription @"No data has been received from an API server. Try again. Or do nothing."
#define kEBInvalidTokenErrorDescription @"Invalid token pushed to the -sendRequestWithToken:asynchronous:andCallbackBlock: EBVKAPI's method"
#define kEBInvaildSDKRequestTokenError [NSError errorWithDomain: kEBVKAPIRequestDomain code: -1 userInfo: [NSDictionary dictionaryWithObject: kEBInvalidTokenErrorDescription forKey: NSLocalizedDescriptionKey]]
#define kEBNoDataError [NSError errorWithDomain: kEBVKAPIRequestDomain code: -1 userInfo: [NSDictionary dictionaryWithObject: kEBNoDataErrorDescription forKey: NSLocalizedDescriptionKey]]

@interface EBVKAPIRequest (Private)
@property (nonatomic, retain, readwrite) NSError *lastReceivedError;

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token;
- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret;
- (void)createAsyncConnectonInBackgroundWithParameters:(NSDictionary*)dict;

- (void)runCallbackBlockWithReceivedData:(NSData *)raw_data;

@end


@implementation EBVKAPIRequest
@synthesize methodName = _method_name, format = _method_response_format;
@synthesize lastReceivedError = _last_recieved_error;

- (id)init
{
    if ((self=[super init])) {
     	_method_name = nil;
        _method_params = nil;
        _method_response_format = kEBPreparsedFormat;
        _last_recieved_error = nil;
        _queue = nil;     
    }
    return self;
}


- (id)initWithMethodName:(NSString *)name parameters:(NSDictionary *)params responseFormat:(enum EBVKAPIResponseFormat)response_format
{    
    if ( ! check_for_nil(name, EBNULL)) {
        return (self = nil, self);
    }
    if ((self = [super init])) {
        _method_name = [name copy];
        _method_params = params ? [[NSMutableDictionary alloc] initWithDictionary: params] : nil;
        _method_response_format = response_format;
        _callback_block = nil;
    }
    return self;
}

- (void)dealloc
{
    [_queue release], _queue = nil;
    [_method_params release], _method_params = nil;
    if (_last_recieved_error) [_last_recieved_error release];
    [super dealloc];
}

- (NSDictionary *)parameters
{
    return [_method_params copy];
}


- (void)setParameters:(NSDictionary *)parameters
{
    if (_method_params) {
        [_method_params release];
    }
    _method_params = [[NSMutableDictionary alloc] initWithDictionary: parameters];
}

- (void)setParameterValue:(NSString *)parameter forKey:(NSString *)key
{
    if (! _method_params) {
        _method_params = [[NSMutableDictionary alloc] init];
    }
    [_method_params setObject: parameter forKey: key];
    NSLog(@"Added : %@ %@", key, [_method_params objectForKey: key]);
}

- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret
{
    if ( ! check_for_nil(mid, parameters, secret, EBNULL)) return nil;
    NSMutableString *sig = [NSMutableString stringWithString: mid];
#if NS_BLOCKS_AVAILABLE    
    [[[parameters allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] 
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         [sig appendFormat:@"%@=%@", obj, [parameters objectForKey: obj]];
     }];
#else    
    NSArray *sorted_params_keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (id obj in sorted_params_keys) {
        [sig appendFormat:@"%@=%@", obj, [parameters objectForKey: obj]];
    }
#endif    
    [sig appendFormat:@"%@", secret];
    sig = [NSMutableString stringWithString: [NSString strignWithMD5HashOf: sig]];
    return sig;
}

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token
{    
    NSMutableString *request_body = [[NSMutableString alloc] init];
    NSString *sig = @"";
    if (!_method_params) _method_params = [[NSMutableDictionary alloc] init];
    [_method_params setValue: token.appID forKey: @"api_id"];
    [_method_params setValue: (_method_response_format == kEBPreparsedFormat) ? @"JSON" : @"XML"  forKey: @"format"];
    [_method_params setValue: kVKAPIVersion forKey: @"v"]; /* VK API version */
    [_method_params setValue: _method_name forKey: @"method"];
    
    sig = [self composeSigFromMid: token.mid parameters: _method_params andSecret: token.secret];
#if NS_BLOCKS_AVAILABLE    
    [_method_params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ( [obj isKindOfClass: NSClassFromString(@"NSNumber")]) {
            [_method_params setObject: [obj stringValue] forKey: key];
            obj = [_method_params objectForKey: key];
        }
        [request_body appendFormat: @"&%@=%@", key, [obj stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];  
    }];   
#else        
    for (id key in [_method_params allKeys]) {
        if ( [[_method_params objectForKey: key] isKindOfClass: NSClassFromString(@"NSNumber")]) {
            [_method_params setObject: [[_method_params objectForKey: key] stringValue] forKey: key];
        }
        [request_body appendFormat: @"&%@=%@", key, 
         [[_method_params objectForKey: key] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    }
#endif
    /* Delete first '&' character */
    [request_body deleteCharactersInRange: NSMakeRange(0, 1)]; 
    
    [request_body appendFormat: @"&sid=%@&sig=%@", token.sid, sig];
    NSURL *request_url = [NSURL URLWithString: [NSString stringWithFormat: @"%@?%@", kEBVKAPIServer, request_body]];
    [request_body release], request_body = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: request_url];
    [request setHTTPShouldHandleCookies: NO]; 
    NSString *custom_user_agent = kVKAPIUserAgentString;
    [request setValue: custom_user_agent  forHTTPHeaderField: @"User-Agent"];
    [request setAllHTTPHeaderFields: [NSHTTPCookie requestHeaderFieldsWithCookies: [token cookies]]];
    NSLog(@"(( %@ ))", [[request URL] absoluteString]);
    return [(NSURLRequest*)request autorelease];
}

- (NSInteger)operationsQuantity
{
    @synchronized (_queue) {
        return [_queue operationCount];
    }
}


- (BOOL)sendRequestWithToken: (EBVKAPIToken *)token asynchronous: (BOOL)asynchronous callbackBlock: (EBVKAPICallbackBlock)a_callback_block
{
    if ([_method_params count] < 1) {
        return NO;
    }
    if ( ! check_for_nil(token.secret, token.mid, token.sid, EBNULL)) {
        a_callback_block([EBVKAPIResponse responseWithSDKError: kEBInvaildSDKRequestTokenError]);
        return NO;
    }
    
    if (asynchronous) {      
        if (!_queue) {
            _queue = [NSOperationQueue new];
        }
        /* I use a dictionary to transport a $token and $block between class' methods.
           The main thing why I'm not using ivars for this purpose - it's because EBVKAPIRequest may create a multiple 
           connections (in other words, is't may work as multiple requests) in async mode - so we can't store a $request and 
           $block vars as ivars or smth like this (since they are unique for each request and may change 
           while some of requests will be finished up).
        */
        NSDictionary *dictionary = [[NSDictionary dictionaryWithObjectsAndKeys: [self requestForToken: token], @"request",
                                                                                a_callback_block, @"block", nil] retain];
        NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                         selector: @selector(createAsyncConnectonInBackgroundWithParameters:) 
                                                                           object: dictionary];
        [dictionary release];
        [_queue addOperation: op];
        [op release];
        return ([_queue operationCount] > 0);
        
    } else {
        NSError *tmp_error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                             returningResponse: nil 
                                                         error: &tmp_error];
        if (data) {
            /* But we can run this block by ourselves as well 
              (instead of using a such bridge like EBSmartURLConnection) */
            [EBSmartURLConnection performCallbackBlock: a_callback_block 
                                                  data: data
                                                   raw: (_method_response_format == kEBRawXMLFormat)];
            return (YES);
        } else {
            if (tmp_error) {
                a_callback_block([EBVKAPIResponse responseWithSDKError: tmp_error]);
            }
            return (NO);
        }
    }
    
}

- (void)createAsyncConnectonInBackgroundWithParameters:(NSDictionary*)dict
{ 
    /* Connection will starts working immediately after itself's initialization */ 
    EBSmartURLConnection *smart_connection = [[EBSmartURLConnection alloc] 
                                                    initWithRequest: [dict objectForKey:@"request"]
                                                           delegate: self 
                                                      callbackBlock: [dict objectForKey: @"block"]
                                                     responseFormat: _method_response_format];
    /* Create a loop for prevent the app to exit while our connection is working */
    CFRunLoopRun();
    /* Later, we'll terminate this loop in NSURLConnection delegate' methods */
    [smart_connection release];
}



- (EBVKAPIResponse *)sendRequestWithToken:(EBVKAPIToken *)token
{
    if ( ! check_for_nil(token.secret, token.mid, token.sid, EBNULL)) {
        return (nil);
    }
    
    NSError *tmp_error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                         returningResponse: nil 
                                                     error: &tmp_error];
    if (!data) {
        EBErrorLog(tmp_error);
        [self setLastReceivedError: tmp_error];
        return [EBVKAPIResponse responseWithSDKError: tmp_error];
    } else {
        if (_method_response_format == kEBPreparsedFormat) {
            return [EBVKAPIResponse responseWithObject: 
                                        [[JSONDecoder decoder] parseJSONData: data]];
        } else {
            return [EBVKAPIResponse responseWithRawData: data];
        }
    }    
}



#pragma mark NSURLConnection delegate's

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{ 
    /* Should we care? */
    return;
}
-(void)connection:(EBSmartURLConnection*)connection didReceiveData:(NSData *)data
{
    if ( ! connection.data) {
        [connection setData: [NSMutableData dataWithData: data]];
    } else {
        [connection.data appendData: data];
    }   
}

- (void)connectionDidFinishLoading:(EBSmartURLConnection *)connection
{
    if (connection.data) {
        [connection performCallbackBlock];                                                            
    } else {
        NSError *no_data_error = [NSError errorWithDomain: kEBVKAPIRequestDomain 
                                                     code: 0 
                                                 userInfo: 
                                        [NSDictionary dictionaryWithObject: kEBNoDataErrorDescription
                                                                    forKey: NSLocalizedDescriptionKey]];
        [connection performCallbackBlockWithError: no_data_error]; 
    }
    /* Return to the CFRunLoop() point in the -createAsyncConnectonInBackgroundWithParameters: method */
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(EBSmartURLConnection *)connection didFailWithError:(NSError *)error
{
    [connection performCallbackBlockWithResponse: [EBVKAPIResponse responseWithSDKError: error]];
    [connection performCallbackBlockWithError: error];
    /* Return to the CFRunLoop() point in the -createAsyncConnectonInBackgroundWithParameters: method */
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
