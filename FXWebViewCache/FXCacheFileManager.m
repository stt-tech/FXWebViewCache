//
//  FXCacheFileManager.m
//  FancyMall
//
//  Created by fancy on 16/1/14.
//  Copyright © 2016年 FancyMall. All rights reserved.
//

#import "FXCacheFileManager.h"

@implementation FXCacheFileManager

+(instancetype)shareFileManager
{
    static FXCacheFileManager *cacheFile = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cacheFile = [[FXCacheFileManager alloc] init];
    });
    return  cacheFile;
}
/**caches 的总文件目录 */
-(NSString *)cachesPath
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return cachesPath;
}

/* mall.fancyedu.com   跟目录*/
-(NSString *)createRootCacheFilePath
{
    return  [[self cachesPath] stringByAppendingPathComponent:@"fancyedu.com"];
}

-(void)createFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

-(void)creatRootFileName
{
    NSString *newPath = [self createRootCacheFilePath];
    [self createFileWithPath:newPath];
}

-(void)removeFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
         
        [fileManager removeItemAtPath:path error:nil];
    }
}




@end