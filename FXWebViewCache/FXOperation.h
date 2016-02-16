//
//  FXOperation.h
//  cacheText
//
//  Created by fancy on 15/12/4.
//  Copyright © 2015年 Stt-Ocean. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>


@protocol  FXOperationDelegate<NSObject>

-(void)fxOperationWithData:(NSData *)data response:(NSURLResponse *)response ;

@end


@interface FXOperation : NSOperation<NSURLConnectionDataDelegate>

@property (nonatomic,copy)NSMutableURLRequest *request;

@property (nonatomic,strong)id <FXOperationDelegate>delegate;

@end
