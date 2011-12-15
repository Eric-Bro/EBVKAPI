//
//  EBVKAPIRequest.m
//

#import "EBVKAPIRequest.h"
#import "EBSmartURLConnection.h"
#include "common.h" /* for check_params() */
#import "NSString+EB.h"
/* JSON parsing */
#import "JSONKit.h"

#define kVKAPIVersion @"3.0"

@interface EBVKAPIRequest (Private)

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token;
- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret;
//- (void)runCallbackBlockWithResponseData:(NSData*)data andError:(NSError*)error;
- (void)createAsyncConnectonInBackgroundWithParameters:(NSDictionary*)dict;
@end


@implementation EBVKAPIRequest
@synthesize  parameters = _method_params, methodName = _method_name, format = _method_response_format;
@synthesize  operationCount = _operation_queue_length;


- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret
{
    if ( ! check_params(mid, parameters, secret, EBNULL)) return nil;
    NSMutableString *sig = [NSMutableString stringWithString: mid];
#if NS_BLOCKS_AVAILABLE    
    [[[parameters allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] 
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         [sig appendFormat:@"%@=%@", obj, [parameters valueForKey: obj]];
     }];
#else    
    NSArray *sorted_params_keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (id obj in sorted_params_keys) {
        [sig appendFormat:@"%@=%@", obj, [parameters valueForKey: obj]];
    }
#endif    
    [sig appendFormat:@"%@", secret];
    sig = [NSMutableString stringWithString: [NSString stringWithMD5Hash: sig]];
    return sig;
}

- (id)init
{
    if ((self=[super init])) {
     	_method_name = nil;
        _method_params = nil;
        _method_response_format = EBJSONFormat;
    } else self = nil;
    
    return self;
}


- (id)initWithMethodName:(NSString *)name parameters:(NSDictionary *)params responseFormat:(enum EBVKAPIResponseFormat)response_format
{    
    if ( ! check_params(name, EBNULL)) {
        return (self = nil, self);
    }
    if ((self = [super init])) {
        _method_name = [name copy];
        _method_params = params ? [[NSMutableDictionary alloc] initWithDictionary: params] : nil;
        _method_response_format = response_format;
        
    } else self = nil;
    
    return self;
}

- (void)dealloc
{
    [_queue release];
    [_method_params release], _method_params = nil;
    [super dealloc];
}

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token
{    
    NSMutableString *request_body = [[NSMutableString alloc] init];
    NSString *sig = @"";
    if (!_method_params) _method_params = [[NSMutableDictionary alloc] init];
    [_method_params setValue: token.appID forKey: @"api_id"];
    [_method_params setValue: (_method_response_format == EBJSONFormat) ? @"JSON" : @"XML"  forKey: @"format"];
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
    NSURL *request_url = [NSURL URLWithString: [NSString stringWithFormat: @"https://api.vk.com/api.php?%@", request_body]];
    [request_body release], request_body = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: request_url];
    [request setHTTPShouldHandleCookies: NO]; 
    NSString *custom_user_agent = kVKAPIUserAgentString;
    [request setValue: custom_user_agent  forHTTPHeaderField: @"User-Agent"];
    [request setAllHTTPHeaderFields: [NSHTTPCookie requestHeaderFieldsWithCookies: [token cookies]]];
    
    return [(NSURLRequest*)request autorelease];
}

- (NSInteger)operationCount
{
    return [_queue operationCount];
}


- (BOOL)sendRequestWithToken: (EBVKAPIToken *)token asynchronous: (BOOL)asynchronous andCallbackBlock: (EBVKAPICallbackBlock)a_callback_block
{
    if ( ! check_params(token.secret, token.mid, token.sid, EBNULL)) {
        a_callback_block(nil, [NSError errorWithDomain:@"_ebvkapirequestdomain" code: -1 userInfo: nil]);
        return NO;
    }
    
    if (asynchronous) {      
        if (!_queue) {
            _queue = [NSOperationQueue new];
        }
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self requestForToken: token], @"request", a_callback_block, @"block", nil];
        NSInvocationOperation *invoc = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(createAsyncConnectonInBackgroundWithParameters:) object: dictionary];
        [_queue addOperation: invoc];
        [invoc release];
        return ([_queue operationCount] > 0);
        
    } else {
        NSError *tmp_error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                             returningResponse: nil 
                                                         error: &tmp_error];
        [EBSmartURLConnection runCustomCallbackBlock: a_callback_block
                                            withData: data	 
                                               error: tmp_error	 
                                   andResponseFormat: _method_response_format];
        return (data != nil);
    }
    
}

- (void)createAsyncConnectonInBackgroundWithParameters:(NSDictionary*)dict
{ 
    EBSmartURLConnection *smart_connection = [[EBSmartURLConnection alloc] initWithRequest: [dict objectForKey:@"request"]
                                                                                  delegate: self 
                                                                         withCallbackBlock: [dict objectForKey: @"block"]
                                                                         andResponseFormat: _method_response_format];
    /* Create a loop for prevent the app to exit while our connection is working */
    CFRunLoopRun();
    /* Later, we terminate this loop in NSURLConnection delegate methods */
    [smart_connection release];
}

- (EBVKAPIResponse *)sendRequestWithToken:(EBVKAPIToken *)token
{
    if ( ! check_params(token.secret, token.mid, token.sid, EBNULL)) {
        goto err_exit;
    }
    
    NSError *tmp_error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                         returningResponse: nil 
                                                     error: &tmp_error];
    if (!data) {
        return [EBVKAPIResponse responseWithResponse: nil andError: tmp_error];
    } else {
        switch (_method_response_format) {
            case EBJSONFormat: {
                return [EBVKAPIResponse responseWithResponse: [[JSONDecoder decoder] parseJSONData: data]  
                                                    andError: nil];
            }
            case EBRawXMLFormat: {
                id tmp = [[[NSString alloc] initWithData: data 
                                                encoding: NSUTF8StringEncoding] autorelease];
                 return [EBVKAPIResponse responseWithResponse: tmp andError: nil];
            }
        }
    }
err_exit:
    return nil;
}


#pragma mark NSURLConnection delegate's

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{ 
    
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    EBSmartURLConnection *linked_connection = (EBSmartURLConnection*)connection;
    if (!linked_connection.data) {
        [linked_connection setData: [NSMutableData dataWithData: data]];
    } else {
        [linked_connection.data appendData: data];
    }   
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    EBSmartURLConnection *linked_connection = (EBSmartURLConnection*)connection;
    if (!linked_connection.data) {
        NSError *error = [NSError errorWithDomain: @"_ebvkapidomain" code:1 userInfo:
                          [NSDictionary dictionaryWithObject: @"No data has been received from an API server. Try again." 
                                                      forKey: NSLocalizedDescriptionKey]];
        [(EBSmartURLConnection *)connection runCallbackBlockWithError: error];
        return;
    }
    [(EBSmartURLConnection *)connection runCallbackBlockWithError: nil];
    /* Return to the CFRunLoop() point in the -createAsyncConnectonInBackgroundWithParameters: method */
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [(EBSmartURLConnection *)connection runCallbackBlockWithError: error];
    /* Return to the CFRunLoop() point in the -createAsyncConnectonInBackgroundWithParameters: method */
    CFRunLoopStop(CFRunLoopGetCurrent());
}



#pragma mark Cookies work

+ (NSArray *)dumpAllCookiesForDomain:(NSString *)domain
{    
    NSArray *all_cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
#if NS_BLOCKS_AVAILABLE
    return  [all_cookies objectsAtIndexes: [all_cookies indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(NSHTTPCookie*)obj domain] isEqualToString: domain]) {
            return YES;
        } else return NO;
    }]];
#else
    NSMutableIndexSet *indexses = [[[NSMutableIndexSet alloc] init] autorelease];
    NSUInteger idx = 0;
    for (id obj in all_cookies) {
        if ([[(NSHTTPCookie*)obj domain] isEqualToString: domain]) {
        	[indexses addIndex: idx];
        }
        idx++;
    }
    return ([all_cookies objectsAtIndexes: indexses]);
#endif
    
}

+ (void)setCookies:(NSArray *)new_cookies forDomain:(NSString *)domain
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies: new_cookies 
                                                        /* We have to append the $domain string with "http://", because it'll be an URL */
                                                       forURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://%@", domain]] 
                                              mainDocumentURL: nil];
}


+ (void)cleanUpAllCookiesForDomain:(NSString *)domain
{
    NSHTTPCookieStorage *shared_storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
#if NS_BLOCKS_AVAILABLE
    [[shared_storage cookies] enumerateObjectsUsingBlock:^(NSHTTPCookie *cookie, NSUInteger idx, BOOL *stop) {
        if ([[cookie domain] isEqualToString: domain]) {
            [shared_storage deleteCookie:cookie];
        }
    }];
#else
    for (NSHTTPCookie *cookie in [shared_storage cookies]) {
        if ([[cookie domain] isEqualToString: domain]) {
            [shared_storage deleteCookie:cookie];
        }
	}
#endif
}

@end
