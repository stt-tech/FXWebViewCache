//
//  FXURLCacheProtocol.m
//  FXCacheWebView
//
//  Created by fancy on 15/12/22.
//  Copyright © 2015年 孙婷婷-Ocean. All rights reserved.
//

#import "FXURLCacheProtocol.h"
#import "FXOperation.h"

#import "FXShowContent.h"
#import "FXCachePlist.h"
#import "FXCacheFileManager.h"

#import "FXSendSynRequest.h"
#include <pthread.h>

//#define COUNT  50
#define CacheMB 20

static pthread_rwlock_t rwlock;


//  Sha1加密
@implementation NSString (Sha1)

- (NSString *)sha1
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, ( unsigned int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
@end

static NSString *const kDataKey = @"data";
static NSString *const kResponseKey = @"response";
static NSString *const kRedirectRequestKey = @"redirectRequest";
static NSString *const kLastLoadDate = @"lastLoadDate";
@implementation FXCacheData

/**缓存数据的实现文件*/
@synthesize data = data_;
@synthesize response = response_;
@synthesize date = date_;

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self data] forKey:kDataKey];
    [aCoder encodeObject:[self response] forKey:kResponseKey];
    [aCoder encodeObject:[self redirectRequest] forKey:kRedirectRequestKey];
    [aCoder encodeObject:[self date] forKey:kLastLoadDate];
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil) {
        [self setData:[aDecoder decodeObjectForKey:kDataKey]];
        [self setResponse:[aDecoder decodeObjectForKey:kResponseKey]];
        [self setRedirectRequest:[aDecoder decodeObjectForKey:kRedirectRequestKey]];
        // 将时间 进行解归档
        [self setDate:[aDecoder decodeObjectForKey:kLastLoadDate]];
    }
    return self;
}
@end

@interface FXURLCacheProtocol ()<FXOperationDelegate,NSURLConnectionDataDelegate,NSURLConnectionDelegate>


@end

static NSString *FXCacheURLHeader = @"X-FXCache";

@implementation FXURLCacheProtocol
@synthesize connection = connection_;
@synthesize data = data_;
@synthesize response = response_;


- (NSOperationQueue *)FXOperationQueue
{
    if (!_FXOperationQueue) {
        _FXOperationQueue = [[NSOperationQueue alloc] init];
        _FXOperationQueue.maxConcurrentOperationCount = 3;
    }return _FXOperationQueue;
}
+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        pthread_rwlock_init(&rwlock, NULL);
    });
    if ([[[request URL] scheme] isEqualToString:@"http"] &&
        ([request valueForHTTPHeaderField:FXCacheURLHeader] == nil)
        && [NSURLProtocol propertyForKey:@"refreshcache" inRequest:request] == nil)
    {
        return YES;
    }
    return NO;
}
+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return  request;
}
#pragma mark -- 缓存文件的内容
// 文件的路径
- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest
{
    NSString *cachesPath = [[FXCacheFileManager shareFileManager] createRootCacheFilePath];
    NSString *fileName = [self cacheFileNameWithRequest:aRequest];
    return [cachesPath stringByAppendingPathComponent:fileName];
}
/**缓存文件的文件名*/
-(NSString *)cacheFileNameWithRequest:(NSURLRequest *)aRequest
{
    return [[[aRequest URL] absoluteString] sha1];
}
// 判断缓存是否超时
-(BOOL)cacheTimeIsOutWithDate:(NSDate *)date
{
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:date];// 现在 距离过去的时间
    NSString *str = [NSString stringWithFormat:@"%lf",interval];
    NSString *first = [[str componentsSeparatedByString:@"."] firstObject];
    int intDat = [first intValue];
    NSInteger  index = (NSInteger)(intDat/60);// 将时间转化为分钟
    if (index >=  5){
        return  YES;
    }
    return  NO;
}
/**需要走缓存逻辑*/
-(BOOL)needCacheLogicWithRequest:(NSString *)requestUrl
{
    // 需要走缓存的逻辑
    if (([requestUrl rangeOfString:@"mall.fancyedu.com/"].location == NSNotFound)&&
        ([requestUrl rangeOfString:@"fancymall1.cn-hangzhou.aliappcdn.com/"].location == NSNotFound)&&
        ([requestUrl rangeOfString:@"img.fancyedu.com/"].location == NSNotFound)&&
        ([requestUrl rangeOfString:@"cnzz.com/"].location == NSNotFound)&&
        ([requestUrl rangeOfString:@"g.alicdn.com/"].location == NSNotFound)) {
        return YES;
    }
    return NO;
}
-(void)sendMessageOnMainThread
{
     [[[FXSendSynRequest alloc] init] sendSynRequest];
    NSArray *delete = [[NSUserDefaults standardUserDefaults] objectForKey:FXDELETE];
    if (delete) {
        for (NSString *mark in delete) {
            // 根据标签进行删除
         [self removeItemsWithMark:mark];
        }
    }
}

- (void)startLoading
{
    if ([self needCacheLogicWithRequest:self.request.URL.absoluteString]) {
        NSMutableURLRequest *connectionRequest = [[self request] mutableCopy];
        [connectionRequest setValue:@"" forHTTPHeaderField:FXCacheURLHeader];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest
                                                                    delegate:self];
        [self setConnection:connection];
    }
    else
    {
        if (![self useCache])
        {
            NSMutableURLRequest *connectionRequest = [[self request] mutableCopy];
            [connectionRequest setValue:@"" forHTTPHeaderField:FXCacheURLHeader];
            NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest
                                                                        delegate:self];
            [self setConnection:connection];
            NSLog(@"-----这个地方是关闭了缓存之后---%@",self.request.URL.absoluteString);
        }
        else {
            
            pthread_rwlock_rdlock(&rwlock);
            FXCacheData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachePathForRequest:[self request]]];
            pthread_rwlock_unlock(&rwlock);
            if (cache) {
                NSData *data = [cache data];
                NSURLResponse *response = [cache response];
                NSURLRequest *redirectRequest = [cache redirectRequest];
                if (redirectRequest) {
                    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
                } else
                {
                    NSString *url = self.request.URL.absoluteString;
                    NSLog(@"使用 缓存的 url --%@----%@",url,url.sha1);
                    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    [[self client] URLProtocol:self didLoadData:data];
                    [[self client] URLProtocolDidFinishLoading:self];
                    NSDate *lastDate = cache.date;
                    BOOL timeOut = [self cacheTimeIsOutWithDate:lastDate];
                    if (timeOut){
                        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            FXOperation *operation = [[FXOperation  alloc] init];
                            operation.request = [[self request] mutableCopy];
                            [self.FXOperationQueue  addOperation:operation];
                            operation.delegate = self;
                            dispatch_semaphore_signal(semaphore);
                        });
                    }
                }
            }
            else
            {
                [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
            }
        }
    }
}
- (void)stopLoading
{
    [[self connection] cancel];
}
#pragma mark -- connection的代理方法
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest =  [request mutableCopy];
        [redirectableRequest setValue:nil forHTTPHeaderField:FXCacheURLHeader];
        FXCacheData *cache = [FXCacheData new];
        [cache setResponse:response];
        [cache setData:[self data]];
        [cache setRedirectRequest:redirectableRequest];
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
        if (![self needCacheLogicWithRequest:self.request.URL.absoluteString]) {
            [self appendData:data];
        }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    NSHTTPURLResponse *respon = (NSHTTPURLResponse *)response;
    NSDictionary *responDic = respon.allHeaderFields;
    NSInteger index = [self  versionWithDict:responDic];
    [self findHTTPHeaderWithVS:index];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSHTTPURLResponse *afterResponse = (NSHTTPURLResponse *)response_;
    if(afterResponse.statusCode == 200){
        [[self client] URLProtocolDidFinishLoading:self];
        FXCacheData *cache = [FXCacheData new];
        [cache setResponse:[self response]];
        [cache setData:[self data]];
        [cache setDate:[NSDate date]];
        NSString *cachePath = [self cachePathForRequest:[self request]];
        [self writhData:cache toFile:cachePath];
        [self setConnection:nil];
        [self setData:nil];
        [self setResponse:nil];
    }else
    {
        // 如果数据文成之后 状态码 不为200 既 响应是不成功的 就设置响应失败
        [self setConnection:nil];
        [self setData:nil];
        [self setResponse:nil];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

#pragma mark -- 请求头的判定
-(NSInteger)versionWithDict:(NSDictionary *)headerDic
{
    NSString *str = [headerDic objectForKey:@"vs"];
    NSInteger index = [str integerValue];
    return  index;
}
-(void)findHTTPHeaderWithVS:(NSInteger )vs
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:FXVERSION];
   
    // 本地存储的 版本号 小于 请求头的版本号
    if(!index ){
        index = 0;
    }
    if (index < vs) {
        [[NSUserDefaults standardUserDefaults] setInteger:vs forKey:FXVERSION];
        [self performSelectorOnMainThread:@selector(sendMessageOnMainThread) withObject:nil waitUntilDone:NO];
    }
}

- (BOOL) useCache
{
    BOOL isCache = [[NSUserDefaults standardUserDefaults] boolForKey:FXISCACHE];
//   BOOL  isCache = NO;
    NSLog(@"---isCache   ------%d",isCache);
    if (isCache) {
        NSString *fileName = [[[[self request] URL] absoluteString] sha1];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *fileList = [[NSArray alloc] init];
        fileList = [fileManager contentsOfDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Caches/fancyedu.com"] error:&error];
        for (NSString *str  in fileList) {
            while ([str isEqualToString:fileName]) {
                return YES;
            }
        }
        return  NO;
    }else
    {
        return  NO;
    }
}

#pragma mark -- NSOperation的代理方法
-(void)fxOperationWithData:(NSData *)data response:(NSURLResponse *)response
{
    NSLog(@"----超时时候的处理情况 -----%@",self.request.URL);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);// 如果semaphore的计数器大于1  那么计数器就-1  返回程序继续执行  如果计数器为0 就等待  这里设置的等待时间是一直等待
        NSString *cachePath = [self cachePathForRequest:[self request]];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:cachePath error:nil];
        FXCacheData *cache = [FXCacheData new];
        [cache setResponse:response];
        [cache setData:data];
        [cache setDate:[NSDate date]];
        // 注意的是 这个地方需要打上 重定向
        [self writhData:cache toFile:cachePath];
        dispatch_semaphore_signal(semaphore);// 计数器+ 1  这两句代码中间的代码 每次只允许一个线程进入 这样就有效的保证了多个线程的时候 每次都会只有一个线程进入
    });
}
#pragma mark -- 白名单和黑名单

-(BOOL)withListWithUrl:(NSString *)requestUrl
{
    for (NSString *str in [self witheList]) {
        NSRange range = [requestUrl rangeOfString:str];
        if (range.length > 0) {
            return  YES;
        }
    }
    return  NO;
}
#pragma mark -- 将数据缓存到文件中   plist 文件的路径
-(NSString *)plistFilePath
{
    NSString *filePath = [[FXCachePlist sharedPlist] needRemoveFileName];
    return  filePath;
}
-(void)writhData:(FXCacheData *)cache toFile:(NSString *)cachePath
{
    NSString *requestUrl = self.request.URL.absoluteString;
    NSString *cachesPath = [[FXCacheFileManager shareFileManager] createRootCacheFilePath];
    NSString *mark = [self markInUrl:requestUrl];
    if (![self needCacheLogicWithRequest:requestUrl]) {
//          NSLog(@"------需要写入缓存的 url ：%@",requestUrl);
//        if(
//           ((([requestUrl rangeOfString:@".cnzz.com"].length != 0))&&([requestUrl hasSuffix:@".js"] || [requestUrl hasSuffix:@".css"]))||
//          (([requestUrl hasSuffix:@".png"]||[requestUrl hasSuffix:@".jpg"]||[requestUrl hasSuffix:@".js"]||[requestUrl hasSuffix:@".css"])&&([self withListWithUrl:requestUrl])== YES)||
//           ([requestUrl rangeOfString:@"/app.gif"].length != 0)
//           ||([requestUrl hasSuffix:@""])
////           ||([self withListWithUrl:requestUrl]==YES)
//           ){
            if(
               [requestUrl hasSuffix:@".js"]||[requestUrl hasSuffix:@".css"]||
               [requestUrl hasSuffix:@".png"]||[requestUrl hasSuffix:@".jpg"]||([requestUrl rangeOfString:@"/app.gif"].length != 0)||([requestUrl rangeOfString:@".php"].length != 0)){
                NSLog(@"-----写入本地的url -----%@--",requestUrl);
                // cnzz 下的js 和css以及
            float fl = [[FXShowContent shareManager] folderSizeAtPath:cachesPath];
            NSLog(@"---文件的尺寸 ---%lf",fl);
            if (fl > CacheMB) {
                [[FXCachePlist sharedPlist] removeOldFileAndOldFileName];
            }
            [[FXCachePlist sharedPlist] dataForDataArrayWithUrl:requestUrl.sha1 withMark:mark];
            [[FXCacheFileManager shareFileManager] creatRootFileName];
            BOOL isCache = [[NSUserDefaults standardUserDefaults] boolForKey:FXISCACHE];
                NSLog(@"-后来的 cache只------%d------",isCache);
                if (isCache) {
                    if(fl < 20.0){
                        NSLog(@"需要写入的文件的url ---%@--%@",requestUrl,requestUrl.sha1);
                         pthread_rwlock_wrlock(&rwlock);
                        [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
                         pthread_rwlock_unlock(&rwlock);
                    }else{
                        return;
                    }
                }else{
                    return;
                }
        }
    }
}

#pragma mark - 不走缓存逻辑和存储相关信息
- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}
/**白名单*/
-(NSArray *)witheList
{
     NSArray *witheLis = [[NSUserDefaults standardUserDefaults] objectForKey:FXWITHLIST];
    if(witheLis == nil){
    witheLis = @[@"/channel/index",@"/WEB-UED/fancy/",@"/sys/ic/operation/",@"/goods/",@"/goodsintro/"];
    }
     return witheLis;
}
-(NSArray *)markFromRequest
{
   NSArray *mark = [[NSUserDefaults standardUserDefaults] objectForKey:FXMARKLIST];
    if (mark == nil){
    mark = @[@"index",@"WEB-UED/fancy/",@"sys/ic/operation"];
    }
    return mark;
}

-(NSString *)markInUrl:(NSString *)url
{
    NSArray *array = [self markFromRequest];
    if (array.count) {
        for (NSString *str in array) {
            if ([url rangeOfString:str].length) {
                return str;
            }
        }
        return @"fancyedu.com";
    }
    return @"fancyedu.com";
}

// 根据标签 删除掉 缓存中的内容
-(void)removeItemsWithMark:(NSString *)mark
{
     [[FXCachePlist sharedPlist] removeFileByLabel:mark];
}

@end

/* 白名单
 
 @"/channel/index",@"/WEB-UED/fancy/",@"/sys/ic/operation/",@"/goods/",@"/goodsintro/"
 
 /sys/ic/operation/   
 /WEB-UED/fancy/dist/   js  css 
 /channel/        http://mall.fancyedu.com/channel/listImg.json?pageId=1
 /goodsintro/
 /goods/detail
 // 商品下的json 文件是需要缓存的
 
 mark =     (
 index,
 "/goods/",
 "/sys/ic/operation",
 "/goodsintro/",
 "/WEB-UED/fancy/dist/p",
 "/WEB-UED/fancy/dist/c"
 )
 
  Handlebars
 
 // 在白名单中 添加 app.gif 
 */
