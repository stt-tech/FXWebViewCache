//
//  FXCachePlist.m
//  FancyMall
//
//  Created by fancy on 16/1/14.
//  Copyright © 2016年 FancyMall. All rights reserved.
//

#import "FXCachePlist.h"
#import "FXCacheFileManager.h"
#import "FXShowContent.h"


#define FXCOUNT 1
//#define CacheMB 30.0

@implementation FXCachePlist

+(instancetype)sharedPlist
{
    static FXCachePlist *plist = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!plist) {
            plist = [[FXCachePlist alloc] init];
        }
    });
    return plist;
}

-(NSMutableArray *)readArrayFramePlist
{
    NSArray *_dataArray = [NSArray arrayWithContentsOfFile:[self needRemoveFileName]];
    NSMutableArray *array = [NSMutableArray arrayWithArray:_dataArray];

    return array;
}

-(NSString *)needRemoveFileName
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [cachesPath stringByAppendingPathComponent:@"fileName.plist"];
    return  filePath;
}

-(void)creatFileForCacheFileName
{
    NSString *filePath = [self needRemoveFileName];
     NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) {
        NSArray *array = [NSArray array];
        [array writeToFile:filePath atomically:YES];
    }else
    {return;}
}
// 将数据写入到文件中
-(void)dataForDataArrayWithUrl:(NSString *)url withMark:(NSString *)mark
{
    [self creatFileForCacheFileName];
    NSString *fileName = url;
    NSDictionary *dic;
    NSString *filePath = [self needRemoveFileName];
    NSMutableArray *mutArray = [self readArrayFramePlist];
    if(fileName.length == 40){
//        NSString *path = [[[FXCacheFileManager shareFileManager] createRootCacheFilePath] stringByAppendingPathComponent:url];
        if (mutArray.count > 0) {
            for(int i = 0;i < mutArray.count ;i++){
                NSDictionary *dict = mutArray[i];
                NSString *name = dict[@"fileName"];
                if ([name isEqualToString:fileName]) {
                    [mutArray removeObject:dict];
                    i--;
                }
            }
            dic = @{ @"fileName": fileName,@"mark":mark};
            [mutArray addObject:dic];
            [mutArray writeToFile:filePath atomically:YES];
        }else
        {
            dic = @{ @"fileName": fileName,@"mark":mark};
            [mutArray addObject:dic];
            [mutArray writeToFile:filePath atomically:YES];
        }
    }
}

#pragma mark -- 删除本地的缓存
/**当文件超过一定大小的时候  需要 删除掉 plist 文件中最早的内容 */
-(void)removeOldFileAndOldFileName
{
    NSMutableArray *_dataArray = [self readArrayFramePlist];
        if (_dataArray.count > FXCOUNT) {
            NSArray *mutArray = [_dataArray subarrayWithRange:NSMakeRange(0, FXCOUNT)];
            for (int i = 0; i < FXCOUNT; i++) {
                NSDictionary *dict = mutArray[i];
                NSString *fileName = [[[FXCacheFileManager shareFileManager] createRootCacheFilePath] stringByAppendingPathComponent:dict[@"fileName"]];
                [[FXCacheFileManager shareFileManager] removeFileWithPath:fileName];
                [_dataArray removeObjectAtIndex:0];
            }
            [_dataArray writeToFile:[self needRemoveFileName] atomically:YES];
            mutArray = nil;
        }
}

/**根据标签进行删除*/
-(void)removeFileByLabel:(NSString *)label
{
        NSMutableArray  *_dataArray = [self readArrayFramePlist];
        for (int i=0; i<_dataArray.count; i++) {
            NSDictionary *dict = _dataArray[i];
            NSString *str = dict[@"mark"];
                if ([str isEqualToString:label] == YES){
                  NSString *path = [[[FXCacheFileManager shareFileManager] createRootCacheFilePath] stringByAppendingPathComponent:dict[@"fileName"]];
                    [[FXCacheFileManager shareFileManager] removeFileWithPath:path];
                    [_dataArray removeObject:dict];
                    i--;
                }
            // 删除完毕之后 需要将 内容重新写入到数组中去
            [_dataArray writeToFile:[self needRemoveFileName] atomically:YES];
    }
}

@end
