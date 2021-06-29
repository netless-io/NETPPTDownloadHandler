//
//  NETFileHandler.h
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NETFileHandler : NSObject

+ (BOOL)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError **)error;
+ (BOOL)createDirectory:(NSURL *)path error:(NSError **)error;

- (instancetype)initWithDirectory:(NSString *)dir;

@property (nonatomic, readonly, copy) NSString *directory;

- (NSURL *)publicFilesDir;

- (BOOL)isPublicFilesExist;
- (BOOL)isPresentationFinishDownload:(NSString *)uuid;
- (BOOL)hasBigFileJSON:(NSString *)uuid;
- (BOOL)isFileExistIn:(NSString *)uuid name:(NSString *)name;

- (BOOL)isSlideZipFinishDownload:(NSString *)uuid slideIndex:(NSInteger)slideIndex;
- (void)registerSlideResource:(NSString *)uuid slideIndex:(NSInteger)slideInde;

- (BOOL)unzip:(NSURL *)zip toDestination:(NSURL *)url;
- (BOOL)unzip:(NSURL *)zip toUUID:(NSString *)uuid;

- (NSURL *)uuidDirectory:(NSString *)uuid;
- (NSURL *)bigFile:(NSString *)uuid;
- (NSURL *)infoJSON:(NSString *)uuid;
- (NSURL *)fileIn:(NSString *)uuid name:(NSString *)name;

- (NSString *)directorySize;
- (NSInteger)slideCount:(NSString *)uuid;

@end

NS_ASSUME_NONNULL_END
