//
//	EBVKAPIError.m
//

#import "EBVKAPIError.h"

enum {kErrorModeDefault, kErrorModeWrapper};
static int _mode;


@implementation EBVKAPIError 
@synthesize description = _error_description;
@synthesize code = _error_code;

- (id)initWithErrorObject:(id)error_dictionary
{
	if ( ! [error_dictionary objectForKey: @"error"]) {
		goto err_exit;
	}
    if ((self = [super init])) {
    
        _error_code = 0;
        _error_description = nil;
        _captcha_sid = nil;
        _captcha_url = nil;        
        _error_code = [(NSNumber *)[[error_dictionary objectForKey: @"error"] 
        											  	objectForKey: @"error_code"] intValue];							
        _error_description = [[[error_dictionary objectForKey: @"error"] 
        									     	objectForKey: @"error_msg"] retain];
        if (!_error_description || !_error_code) {
	        goto err_exit;
        }
        _mode = kErrorModeDefault;	
        /* Do we really need to perform a captcha parse? */
		if (_error_code == EBErrorCaptchaNeeded) {
			_captcha_sid = [[[error_dictionary objectForKey: @"error"] 
        								       	valueForKey: @"captcha_sid"] retain];
        	_captcha_url = [[NSURL alloc] initWithString:
        						[[error_dictionary objectForKey: @"error"] objectForKey: @"captcha_img"]];
       		if (!_captcha_url || !_captcha_sid) {
	       		goto err_exit;
       		}
  			// [self parseCaptcha];	
		}     
    } else self = nil;
    return self;
    
err_exit:
	return (self=nil, self);
}

- (id)initWithNSError:(NSError *)error
{
	if (!error) return (self=nil, self);
	if ((self = [super init])) {
		_error_code = kEBErrorInternalSDKIssue;
        _error_description = [error localizedDescription];
        _mode = kErrorModeWrapper;
	}
	return (self);
}

+ (id)errorWithObject:(id)error_dictionary
{
	return [[[[self class] alloc] initWithErrorObject: error_dictionary] autorelease];
}

+ (id)errorWithNSError:(NSError *)error
{
	return [[[[self class] alloc] initWithNSError: error] autorelease];
}

- (void)dealloc
{
	[_error_description release];
	[super dealloc];
}

@end