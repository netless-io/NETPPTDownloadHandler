//
//  NETPPTDownloader.h
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/28.
//

#import <Foundation/Foundation.h>
#import <Whiteboard/Whiteboard.h>
NS_ASSUME_NONNULL_BEGIN


@protocol NETPPTDownloadDelegate <NSObject>

/** if error is nil, download is success */
- (void)downloadPublicZip:(NSError * _Nullable)error;
/** if error is nil, download is success */
- (void)downloadPresentationZip:(NSString *)taskUUID error:(NSError * _Nullable)error;
/** if error is nil, download is success */
- (void)downloadSlideZip:(NSString *)taskUUID index:(NSInteger)slideIndex error:(NSError * _Nullable)error;
/** if error is nil, download is success */
- (void)downloadShareResource:(NSString *)taskUUID index:(NSInteger)slideIndex name:(NSString *)name error:(NSError * _Nullable)error;

@end


@interface NETPPTDownloader : NSObject

@property (nonatomic, strong, readonly) NSURL *directory;
@property (nonatomic, weak) id<NETPPTDownloadDelegate> delegate;

- (instancetype)initWithDir:(NSURL *)directory;

/** downloadPublic if not exist */
- (void)downloadPublicZipIfNotExist;
- (void)onRoomState:(WhiteDisplayerState *)state;
- (NSString *)directorySize;

#pragma mark - Unit Test
- (NSArray <NSString *>*)extractUUIDFrom:(NSString *)src;
- (void)prepareDownload:(NSString *)uuid slideIndex:(NSInteger)slideIndex;

@end

NS_ASSUME_NONNULL_END
