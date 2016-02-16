//
//  FXCacheFileManager.h
//  FancyMall
//
//  Created by fancy on 16/1/14.
//  Copyright © 2016年 FancyMall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FXCacheFileManager : NSObject

+(instancetype)shareFileManager;

/**caches 的总文件目录 */
-(NSString *)cachesPath;
/* mall.fancyedu.com   跟目录*/
-(NSString *)createRootCacheFilePath;

-(void)creatRootFileName;


/**删除文件 并且有一个返回值*/
-(void)removeFileWithPath:(NSString *)path;

@end
