//
//  NETDownloader.h
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^NETDownloaderCompletionHandler)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface NETDownloader : NSObject

@property (copy, nonatomic, readonly) NSString *uuid;
@property (copy, nonatomic, readonly) NSURL *baseURL;
@property (copy, nonatomic) NSDictionary *shareInfo;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUUID:(NSString *)uuid;
- (instancetype)initWithUUID:(NSString *)uuid baseURL:(NSURL *)baseURL;

#pragma mark - download
- (void)downloadPublicZip:(NETDownloaderCompletionHandler)completionHandler;
- (void)downloadPresentationZip:(NETDownloaderCompletionHandler)completionHandler;
- (void)downloadResource:(NSString *)name completionHandler:(NETDownloaderCompletionHandler)completionHandler;
- (void)downloadSlideResource:(NSInteger)slideIndex completionHandler:(NETDownloaderCompletionHandler)completionHandler;

#pragma mark - task
- (void)cancelCurrentTask;
- (void)invalidateAndCancel;

@end

NS_ASSUME_NONNULL_END
