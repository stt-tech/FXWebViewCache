//
//  FXShowContent.m
//  FancyMall
//
//  Created by fancy on 16/1/14.
//  Copyright © 2016年 FancyMall. All rights reserved.
//

#import "FXShowContent.h"

@implementation FXShowContent

+(instancetype)shareManager
{
    static FXShowContent *content = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!content ) {
            content = [[FXShowContent alloc] init];
        }
    });
    return content;
}

-(void)show
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *caches = [cachesPath stringByAppendingPathComponent:@"fancyedu.com"];
    float fl = [self folderSizeAtPath:caches];
    if (fl > 5.0) {
        [self showAlertViewWithMessage:@"内存已经超过了 5.0 M"];
    }
}
-(void)showAlertViewWithMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alertView show];
}
 
-(long long)fileSizeAtPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager isExecutableFileAtPath:filePath]) {
        long  long  myFileSize = [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
        return myFileSize;
    }
    return  0;
}
// 计算目录下的文件的大小 
//- (float) folderSizeAtPath:(NSString*) folderPath
//{
//    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
//    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
//    NSString *fileName;
//    unsigned long long int fileSize = 0;
//    while (fileName = [filesEnumerator nextObject]) {
//        NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:[folderPath stringByAppendingPathComponent:fileName] traverseLink:YES];
//        fileSize += [fileDictionary fileSize];
//    }
//    float  size= fileSize/1024.0/1024.0;
//    return size;
//}

- (float ) folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

@end
