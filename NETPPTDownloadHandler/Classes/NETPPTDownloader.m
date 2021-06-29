//
//  NETPPTDownloader.m
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/28.
//

#import "NETPPTDownloader.h"
#import "NETDownloader.h"
#import "NETFileHandler.h"

@interface NETPPTDownloader ()
@property (nonatomic, strong, readwrite) NSURL *directory;
@property (nonatomic, strong) NETFileHandler *fileManager;
@property (nonatomic, strong) NETDownloader *downloader;
@property (nonatomic, assign) NSInteger slideIndex;
@property (nonatomic, copy, nullable) NSString *resourceName;
@end

NSString * const NETPPTResponseSerializationErrorDomain = @"link.netless.error.serialization.response";
NSString * const NETPPTOperationFailingURLResponseErrorKey = @"link.netless.serialization.response.error.response";

@implementation NETPPTDownloader

- (instancetype)initWithDir:(NSURL *)directory {
    if (self = [super init]) {
        _directory = directory;
        _fileManager = [[NETFileHandler alloc] initWithDirectory:directory.absoluteString];
        _slideIndex = 1;
    }
    return self;
}

// for unitTest
- (void)prepareDownload:(NSString *)uuid slideIndex:(NSInteger)slideIndex {
    if (![self.downloader.uuid isEqualToString:uuid]) {
        [self.downloader invalidateAndCancel];
    }
    self.slideIndex = slideIndex;
    self.downloader = [[NETDownloader alloc] initWithUUID:uuid];
    [self downloadPresentation];
}

- (void)updateUUID:(NSString *)uuid slideIndex:(NSInteger)slideIndex baseURL:(NSURL *)baseURL {
    
    if ([self.downloader.uuid isEqualToString:uuid] && slideIndex == self.slideIndex && [baseURL.absoluteString isEqualToString:self.downloader.baseURL.absoluteString]) {
        return;
    }
    
    if (self.slideIndex != slideIndex && self.resourceName && [self inNextSlide:self.resourceName]) {
        [self.downloader cancelCurrentResource];
    }
    
    self.resourceName = nil;
    self.slideIndex = slideIndex;

    if (![self.downloader.uuid isEqualToString:uuid]) {
        [self.downloader invalidateAndCancel];
        self.downloader = [[NETDownloader alloc] initWithUUID:uuid baseURL:baseURL];
        [self downloadPresentation];
    }
}

- (void)downloadPresentation {
    NSString *uuid = self.downloader.uuid;
    
    if ([self.fileManager isPresentationExist:uuid]) {
        [self downloadNextSlide];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    [self.downloader downloadPresentationZip:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"download slide location:%@ response:%@", location.absoluteString, response);

        if (error) {
            if ([weakSelf.delegate respondsToSelector:@selector(downloadCommonZip:error:)]) {
                [weakSelf.delegate downloadCommonZip:uuid error:error];
            }
        } else {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
                [weakSelf.fileManager unzipPptZip:location uuid:uuid];
                NSData *data = [NSData dataWithContentsOfURL:[weakSelf.fileManager shareJSONFile:uuid]];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([weakSelf.downloader.uuid isEqualToString:uuid]) {
                    weakSelf.downloader.shareInfo = json;
                }
            } else if ([weakSelf.delegate respondsToSelector:@selector(downloadCommonZip:error:)]) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                           NSURLErrorFailingURLErrorKey:[response URL],
                                           NETPPTOperationFailingURLResponseErrorKey: urlResponse};
                NSError *error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
                [weakSelf.delegate downloadCommonZip:uuid error:error];
            }
        }
        [weakSelf downloadNextSlide];
    }];
}

- (void)downloadNextSlide
{
    NSInteger nextSlideIndex = self.slideIndex + 1;
    NSString *uuid = self.downloader.uuid;

    if (nextSlideIndex > [self.fileManager slideCount:uuid]) {
        NSLog(@"finish at SlideIndex: %ld", nextSlideIndex - 1);
        [self downloadShareResource:@""];
        return;
    } else if ([self.fileManager isSlideResourceZipFinish:uuid slideIndex:nextSlideIndex]) {
        self.slideIndex += 1;
        [self downloadNextSlide];
        return;
    }

    __weak typeof(self)weakSelf = self;
    [self.downloader downloadSlideResource:nextSlideIndex completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"download slide location:%@ response:%@", location.absoluteString, response);
        if (error) {
            if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
                [weakSelf.delegate downloadSlideZip:uuid index:nextSlideIndex error:error];
            }
        } else {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
                [weakSelf.fileManager unzipPptZip:location uuid:uuid];
                if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
                    [weakSelf.delegate downloadSlideZip:uuid index:nextSlideIndex error:nil];
                }
            } else if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                           NSURLErrorFailingURLErrorKey:[response URL],
                                           NETPPTOperationFailingURLResponseErrorKey: urlResponse};

                NSError *error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
                [weakSelf.delegate downloadSlideZip:uuid index:nextSlideIndex error:error];
            }
        }
        if (weakSelf.slideIndex == nextSlideIndex) {
            weakSelf.slideIndex += 1;
            [weakSelf downloadNextSlide];
        } else {
            [weakSelf downloadNextSlide];
        }
    }];
}

- (BOOL)inNextSlide:(NSString *)name {
    
    NSInteger nextSlideIndex = self.slideIndex + 1;
    NSString *slideIndexKey = [NSString stringWithFormat:@"%ld", (long)nextSlideIndex];
    NSArray<NSDictionary *> *list = self.downloader.shareInfo[slideIndexKey];

    NSInteger __block index = -1;
    [list enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"name"] isEqualToString:name]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index != -1;
}

- (void)downloadShareResource:(NSString *)lastName {
    
    NSInteger nextSlideIndex = self.slideIndex + 1;
    NSString *uuid = self.downloader.uuid;

    if (![self.fileManager isSlideResourceZipFinish:uuid slideIndex:nextSlideIndex]) {
        [self downloadNextSlide];
        return;
    }
    
    if (!self.downloader.shareInfo) {
        return;
    }
    
    NSString *slideIndexKey = [NSString stringWithFormat:@"%ld", (long)nextSlideIndex];
    NSArray<NSDictionary *> *list = self.downloader.shareInfo[slideIndexKey];

    NSInteger __block index = -1;
    [list enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"name"] isEqualToString:lastName]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    NSInteger nextResourceIndex = index + 1;
    NSString *name;
    if ([list count] > nextResourceIndex) {
        name = list[nextResourceIndex][@"name"];
    }
    if (!name) {
        self.slideIndex += 1;
        [self downloadShareResource:@""];
        return;
    }

    self.resourceName = name;
    __weak typeof(self)weakSelf = self;
    [self.downloader downloadResource:name completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if ([weakSelf.delegate respondsToSelector:@selector(downloadShareResource:index:name:error:)]) {
                [weakSelf.delegate downloadShareResource:uuid index:nextSlideIndex name:name error:error];
            }
        } else {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
                NSURL *fileURL = [weakSelf.fileManager resourceFileIn:uuid name:name];
                [NETFileHandler copyItemAtURL:location toURL:fileURL error:nil];
                if ([weakSelf.delegate respondsToSelector:@selector(downloadShareResource:index:name:error:)]) {
                    [weakSelf.delegate downloadShareResource:uuid index:nextSlideIndex name:name error:nil];
                }
            } else if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                           NSURLErrorFailingURLErrorKey:[response URL],
                                           NETPPTOperationFailingURLResponseErrorKey: urlResponse};

                NSError *error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
                [weakSelf.delegate downloadSlideZip:uuid index:nextSlideIndex error:error];
            }
        }
        [weakSelf downloadShareResource:name];
    }];
}

// https://www.advancedswift.com/regex-capture-groups/
- (NSArray <NSString *>*)extractUUIDFrom:(NSString *)src {
    NSRegularExpression *reg = [[NSRegularExpression alloc] initWithPattern:@"pptx://(\\S+)/dynamicConvert/([^/]+)/([^.]+).slide" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [reg matchesInString:src options:0 range:NSMakeRange(0, src.length)];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:3];
    for (NSTextCheckingResult *textResult in results) {
        NSInteger number = [textResult numberOfRanges];
        for (int i = 0; i < number; i++) {
            NSRange range = [textResult rangeAtIndex:i];
            if (NSEqualRanges(range, NSMakeRange(0, src.length))) {
                continue;
            }
            NSString *subString = [src substringWithRange:range];
            [array addObject:subString];
        }
    }
    return array;
}

- (void)onRoomState:(WhiteDisplayerState *)state
{
    if (state.sceneState) {
        WhiteScene *scene = state.sceneState.scenes[state.sceneState.index];
        // TODO: download zip by scenes not ppt info.json
        if ([scene.ppt.src hasPrefix:@"pptx://"]) {
            NSArray *info = [self extractUUIDFrom:scene.ppt.src];
            if ([info count] == 3) {
                NSString *domain = info[0];
                NSString *taskUUID = info[1];
                NSInteger slideIndex = [info[2] integerValue];
                NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", domain]];
                [self updateUUID:taskUUID slideIndex:slideIndex baseURL:baseURL];
            }
        }
    }
}

@end
