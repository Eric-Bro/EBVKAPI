//
//  EBSmartURLConnection.m
//  

#import "EBSmartURLConnection.h"
#import "JSONKit.h"

@implementation EBSmartURLConnection
@synthesize data = _data, response = _response;

- (id)initWithRequest: (NSURLRequest *)request 
             delegate: (id)delegate 
    withCallbackBlock: (EBVKAPICallbackBlock)callbackBlock
    andResponseFormat: (enum EBVKAPIResponseFormat)format
{
    if (!callbackBlock) return (self = nil, self);
    if (self == nil) return nil;
    
    _callback_block = Block_copy(callbackBlock);
    [self setData: nil];
    [self setResponse: nil];
    _response_format = format;
    
    self = [super initWithRequest: request delegate: delegate];
    [self start];
    return self;
}

- (void)dealloc
{
    if (_data)     [_data release];
    if (_response) [_response release];
    
    [super dealloc];
}


- (void)runCallbackBlockWithError: (NSError*)error
{
    if ( ! _callback_block) {
        @throw [NSException exceptionWithName:@"There isn't a callback block" reason:@"" userInfo: nil]; 
        return;
    }
    if ( ! self.data) {
        _callback_block(nil, error);
    } else {
        switch (_response_format) {
            case EBJSONFormat: {
                id tmpJSON = [[JSONDecoder decoder] parseJSONData: self.data];
                _callback_block(tmpJSON, nil);
            }
                break;
            case  EBRawXMLFormat: {
                id tmpRaw = [[[NSString alloc] initWithData: self.data 
                                                   encoding: NSUTF8StringEncoding] autorelease];
                _callback_block([NSDictionary dictionaryWithObject: tmpRaw forKey: @"response"], nil);
            }
                break;
        }
    }
    Block_release(_callback_block);
}


+ (void)runCustomCallbackBlock:(EBVKAPICallbackBlock)callback_block 
                      withData:(NSData *)data 
                         error:(NSError *)error
             andResponseFormat:(enum EBVKAPIResponseFormat)format
{
    EBSmartURLConnection *tmp_connection = [[EBSmartURLConnection alloc] initWithRequest: [NSURLRequest requestWithURL: [NSURL URLWithString:@""]] 
                                                                                delegate: self 
                                                                       withCallbackBlock: callback_block
                                                                       andResponseFormat: format];
    [tmp_connection setData: [NSMutableData dataWithData: data]];
    [tmp_connection runCallbackBlockWithError: error];
    [tmp_connection release];
    
}

@end
