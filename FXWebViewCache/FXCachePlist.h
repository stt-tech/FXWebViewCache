//
//  FXCachePlist.h
//  FancyMall
//
//  Created by fancy on 16/1/14.
//  Copyright © 2016年 FancyMall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FXCachePlist : NSObject

+(instancetype)sharedPlist;

-(NSString *)needRemoveFileName;

-(void)dataForDataArrayWithUrl:(NSString *)url withMark:(NSString *)mark;


-(void)removeOldFileAndOldFileName;

-(NSMutableArray *)readArrayFramePlist;

//-(void)creatFileWithWithList;
/**将数据写入到文件中去*/
//-(void)dataToPlist:(NSMutableArray *)mutArray;

/**将数据进行删除*/
-(void)removeFileByLabel:(NSString *)label;

@end
