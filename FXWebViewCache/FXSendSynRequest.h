//
//  FXSendSynRequest.h
//  FXWBCacheDemo
//
//  Created by fancy on 16/1/16.
//  Copyright © 2016年 孙婷婷-Ocean. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FXVERSION   @"newVersion"

#define FXWITHLIST @"WitheList"

#define FXMARKLIST @"MarkList"

#define FXDELETE @"delete"

#define FXDOMAIN @"domain"

#define FXCACHE @"cache"

#define FXISCACHE @"isCache"

@interface FXSendSynRequest : NSObject

+(instancetype)sharedSendSynRequest;
/**发送数据请求*/
-(void)sendSynRequest;
/**判断版本号是否相同*/

//-(void)juedeVersion:(NSString *)vs andOldVersion:(NSString *)old;

@end
