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

- (NSURL *)publicFilesDirectory;
- (BOOL)isPublicFilesExist;
- (BOOL)isPresentationExist:(NSString *)uuid;
- (BOOL)isShareJSONExist:(NSString *)uuid;
- (BOOL)isSlideResourceZipFinish:(NSString *)uuid slideIndex:(NSInteger)slideIndex;
- (BOOL)isResourceExistIn:(NSString *)uuid name:(NSString *)name;
- (BOOL)unzipPptZip:(NSURL *)zip uuid:(NSString *)uuid;

- (NSURL *)uuidDirectory:(NSString *)uuid;
- (NSURL *)shareJSONFile:(NSString *)uuid;
- (NSURL *)infoJSONFile:(NSString *)uuid;
- (NSURL *)resourceFileIn:(NSString *)uuid name:(NSString *)name;
- (NSInteger)slideCount:(NSString *)uuid;

@end

NS_ASSUME_NONNULL_END
