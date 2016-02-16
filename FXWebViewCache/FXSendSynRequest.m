//
//  FXSendSynRequest.m
//  FXWBCacheDemo
//
//  Created by fancy on 16/1/16.
//  Copyright © 2016年 孙婷婷-Ocean. All rights reserved.
//

#import "FXSendSynRequest.h"



@implementation FXSendSynRequest

+(instancetype)sharedSendSynRequest
{
    static FXSendSynRequest  *request = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!request) {
            request = [[FXSendSynRequest alloc] init];
        }
    });
    return  request;
}

-(void)sendSynRequest
{
    NSURL *url = [NSURL URLWithString:@"http://daily.mall.fancyedu.com//cache/getCacheDTO.json"];
    NSURLRequest *newRequest = [[NSURLRequest alloc] initWithURL:url];
    NSMutableURLRequest *connectionRequest = [newRequest mutableCopy];
    [connectionRequest setValue:@"" forHTTPHeaderField:@"X-FXCache"];
    NSData *received = [NSURLConnection sendSynchronousRequest:connectionRequest returningResponse:nil error:nil];
    NSDictionary *cacheData = [NSJSONSerialization JSONObjectWithData:received options:NSJSONReadingMutableLeaves error:nil];
    if (cacheData != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:cacheData forKey:FXCACHE];
    }
    if (cacheData != nil) {
        [self saveDataWithDict:cacheData];
    }
}

-(void)saveDataWithDict:(NSDictionary *)cacheData
{
//    NSString *version = cacheData[@"version"];
//    [[NSUserDefaults standardUserDefaults] setObject:version forKey:FXVERSION];
    NSArray *delete = cacheData[@"delete"];
    if (delete!= nil) {
        [[NSUserDefaults standardUserDefaults] setObject:delete forKey:FXDELETE];
    }
    NSArray *domain = cacheData[@"domain"];
    if (domain) {
        [[NSUserDefaults standardUserDefaults] setObject:domain forKey:FXDOMAIN];
    }
    NSArray *mark = cacheData[@"mark"];
    if (mark) {
        [[NSUserDefaults standardUserDefaults] setObject:mark forKey:FXMARKLIST];
    } 
    NSString *isWithe = cacheData[@"isWithe"];
    if (isWithe) {
        NSArray *withe = cacheData[@"withe"];
        if (withe) {
            [[NSUserDefaults standardUserDefaults] setObject:withe forKey:FXWITHLIST];
        }
    }
    NSString  *isCache = cacheData[@"isCache"];
    
    [[NSUserDefaults standardUserDefaults] setObject:isCache forKey:FXISCACHE];

    NSLog(@"黑白名单-----%@=------%@",cacheData,isCache);
}


@end
