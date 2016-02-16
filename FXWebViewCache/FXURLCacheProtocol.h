//
//  FXURLCacheProtocol.h
//  FXCacheWebView
//
//  Created by fancy on 15/12/22.
//  Copyright © 2015年 孙婷婷-Ocean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@interface NSString (Sha1)

-(NSString *)sha1;

@end


@interface FXCacheData : NSObject

@property (strong, nonatomic)NSData * data ;

@property (strong, nonatomic)NSURLResponse * response ;

@property (strong, nonatomic)NSURLRequest * redirectRequest;

@property (strong, nonatomic)NSDate *date;


@end


@interface FXURLCacheProtocol : NSURLProtocol

@property (strong, nonatomic, readwrite) NSURLConnection * connection;

@property (strong, nonatomic) NSMutableData * data;

@property (strong, nonatomic) NSURLResponse * response;

@property (strong, nonatomic) NSOperationQueue * FXOperationQueue;

/**白名单  需要缓存的关键字*/
-(NSArray *)witheList;


/**是否需要走缓存逻辑*/
-(BOOL)needCacheLogicWithRequest:(NSString *)requestUrl;


@end


