//
//  NSString+EB.m
//
#import "NSString+EB.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (EBUtils)

- (NSString *)stringBetweenString: (NSString *)left_string andString: (NSString *)rigth_string
{
    NSRange left_string_range  = [self rangeOfString: left_string];
    NSRange rigth_string_range = [self rangeOfString: rigth_string];
    if (left_string_range.location == NSNotFound || rigth_string_range.location == NSNotFound) {
        return nil;
    }
    id temp = [self substringFromIndex:left_string_range.location + left_string_range.length];
    NSString *between = [temp substringToIndex: [temp rangeOfString: rigth_string].location];
    return  between;
}

+ (NSString *)stringWithMD5Hash: (NSString *)source
{
    const char *string = [source UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, (unsigned int)strlen(string), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity: CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i< CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

- (NSString *)MD5Hash
{
    return [NSString stringWithMD5Hash: self];
}
@end