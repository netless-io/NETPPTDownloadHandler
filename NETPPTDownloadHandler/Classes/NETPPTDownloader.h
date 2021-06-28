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

- (void)downloadCommonZip:(NSString *)taskUUID error:(NSError * _Nullable)error;
- (void)downloadSlideZip:(NSString *)taskUUID index:(NSInteger)slideIndex error:(NSError * _Nullable)error;
- (void)downloadShareResource:(NSString *)taskUUID index:(NSInteger)slideIndex name:(NSString *)name error:(NSError * _Nullable)error;

@end


@interface NETPPTDownloader : NSObject

@property (nonatomic, strong, readonly) NSURL *directory;
@property (nonatomic, weak) id<NETPPTDownloadDelegate> delegate;

- (instancetype)initWithDir:(NSURL *)directory;

- (void)onRoomState:(WhiteDisplayerState *)state;

@end

NS_ASSUME_NONNULL_END
