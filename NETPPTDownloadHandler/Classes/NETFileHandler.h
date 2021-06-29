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

- (BOOL)unzip:(NSURL *)zip toDestination:(NSURL *)url;
- (BOOL)unzip:(NSURL *)zip toUUID:(NSString *)uuid;

- (NSURL *)uuidDirectory:(NSString *)uuid;
- (NSURL *)bigFile:(NSString *)uuid;
- (NSURL *)infoJSON:(NSString *)uuid;
- (NSURL *)fileIn:(NSString *)uuid name:(NSString *)name;

- (NSDictionary * _Nullable)downloadRecord:(NSString *)uuid;
- (void)writeRecord:(NSDictionary *)info toUUID:(NSString *)uuid;
- (NSString *)directorySize;
- (NSInteger)slideCount:(NSString *)uuid;

@end

NS_ASSUME_NONNULL_END
