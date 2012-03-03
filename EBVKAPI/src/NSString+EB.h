//
//  NSString+EB.h
//


#import <Foundation/Foundation.h>

@interface NSString (EBUtils)
- (NSString *)stringByAppendingPrefix:(NSString *)prefix;
- (NSString *)stringBetweenString: (NSString *)left_string andString: (NSString *)rigth_string;
- (NSString *)MD5Hash;
+ (NSString *)strignWithMD5HashOf: (NSString *)source;

@end
