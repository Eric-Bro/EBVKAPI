//
//  EBVKAPICookies.m
//  EBVKAPI
//
//  Created by Eric Broska on 03.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBVKAPICookies.h"
#import "NSString+EB.h"

#define kEBHTTPPrefix @"http://"

@implementation EBVKAPICookies

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
        ++idx;
    }
    return ([all_cookies objectsAtIndexes: indexses]);
#endif
    
}



+ (void)setCookies:(NSArray *)new_cookies forDomain:(NSString *)domain
{
    /* We have to append the $domain string with "http://", because it'll be an URL */
    if ( ! [domain hasSuffix: kEBHTTPPrefix]) {
        domain = [domain stringByAppendingPrefix: kEBHTTPPrefix];
    }
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies: new_cookies 
     
                                                       forURL: [NSURL URLWithString: domain] 
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
