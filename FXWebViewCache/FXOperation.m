//
//  FXOperation.m
//  cacheText
//
//  Created by fancy on 15/12/4.
//  Copyright © 2015年 Stt-Ocean. All rights reserved.
//

#import "FXOperation.h"

@implementation FXOperation
{
    NSMutableData *_data;
    NSURLResponse *_response;
}
-(void)main
{
    @autoreleasepool {
        // 在自己从谢 操作的时候 需要 自己创建自动释放池
        if(self.isCancelled) return;
        _data = [NSMutableData data];
        _response = [[NSURLResponse alloc] init];
        // 发送请求 
        NSMutableURLRequest *connectionRequest =  [[self request] mutableCopy];
        [connectionRequest setValue:@"" forHTTPHeaderField:@"X-FXCache"];
       [NSURLConnection connectionWithRequest:connectionRequest delegate:self];
        [[NSRunLoop  currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = response;
}
-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    return request;
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
// 完成操作时候 下载时候进行的操作
    if ([self.delegate respondsToSelector:@selector(fxOperationWithData:response:)]) {
        
        [self.delegate fxOperationWithData:_data response:_response];
    }
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"error %@===",error);

}


@end
