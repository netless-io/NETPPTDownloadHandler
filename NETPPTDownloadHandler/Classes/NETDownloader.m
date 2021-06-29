//
//  NETDownloader.m
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/26.
//

#import "NETDownloader.h"

@interface NETDownloader ()
@property (copy, nonatomic, nonnull) NSString *uuid;
@property (copy, nonatomic, nonnull) NSURL *baseURL;
@property (copy, nonatomic, nonnull) NSURLSession *session;
@end

@implementation NETDownloader

static NSString *baseURLString = @"https://convertcdn.netless.link";

- (instancetype)initWithUUID:(NSString *)uuid {
    return [self initWithUUID:uuid baseURL:[NSURL URLWithString:baseURLString]];
}

- (instancetype)initWithUUID:(NSString *)uuid baseURL:(NSURL *)baseURL {
    if (self = [super init]) {
        _uuid = uuid;
        _baseURL = baseURL;
        _session = [NSURLSession sharedSession];
    }
    return self;
}

#pragma mark - Download
- (void)download:(NSURLRequest *)urlRequest completionHandler:(NETDownloaderCompletionHandler)completionHandler {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:urlRequest completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(location, response, error);
        }
    }];
    [downloadTask resume];
}

- (void)downloadPublicZip:(NETDownloaderCompletionHandler)completionHandler {
    [self download:[self publicZip] completionHandler:completionHandler];
}

- (void)downloadPresentationZip:(NETDownloaderCompletionHandler)completionHandler
{
    [self download:[self presentationZip] completionHandler:completionHandler];
}

- (void)downloadSlideResource:(NSInteger)slideIndex completionHandler:(NETDownloaderCompletionHandler)completionHandler
{
    [self download:[self slideZip:slideIndex] completionHandler:completionHandler];
}

- (void)downloadResource:(NSString *)name completionHandler:(NETDownloaderCompletionHandler)completionHandler {
    [self download:[self resourceURL:name] completionHandler:completionHandler];
}

#pragma mark - Task Control
- (void)cancelCurrentResource {
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *resourceURLString = obj.originalRequest.URL.absoluteString;
            if ([resourceURLString hasPrefix:self.baseURL.absoluteString] && ![resourceURLString hasSuffix:@".zip"]) {
                [obj cancel];
            }
        }];
    }];
}

- (void)invalidateAndCancel {
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.originalRequest.URL.absoluteString hasPrefix:self.baseURL.absoluteString]) {
                [obj cancel];
            }
        }];
    }];
}

#pragma mark - NSURLRequest

- (NSURLRequest *)resourceURL:(NSString *)name {
    return  [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:name relativeToURL:self.baseURL]];
}

- (NSURLRequest *)publicZip {
    return  [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"/publicFiles.zip" relativeToURL:self.baseURL]];
}

- (NSURLRequest *)pptZip {
    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"/dynamicConvert/%@.zip", self.uuid] relativeToURL:self.baseURL]];
}

- (NSURLRequest *)presentationZip {
    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"/dynamicConvert/%@/presentationML.zip", self.uuid] relativeToURL:self.baseURL]];
}

- (NSURLRequest *)slideZip:(NSInteger )slideIndex {
    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"/dynamicConvert/%@/resources/resource%ld.zip", self.uuid, (long)slideIndex] relativeToURL:self.baseURL]];
}

@end
