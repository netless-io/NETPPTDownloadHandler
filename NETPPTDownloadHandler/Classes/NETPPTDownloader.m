//
//  NETPPTDownloader.m
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/28.
//

#import "NETPPTDownloader.h"
#import "NETDownloader.h"
#import "NETFileHandler.h"

#define NSLog(...) /* replace NSLog method with nothing/blank */
@interface NETPPTDownloader ()
@property (nonatomic, strong, readwrite) NSURL *directory;
@property (nonatomic, strong) NETFileHandler *fileManager;
@property (nonatomic, strong) NETDownloader *downloader;
@property (nonatomic, assign) NSInteger downloadSlideIndex;
@property (nonatomic, assign) NSInteger slideIndex;
@property (nonatomic, assign, getter=isFinished) BOOL finish;
@property (nonatomic, copy, nullable) NSString *resourceName;
@end

NSString * const NETPPTResponseSerializationErrorDomain = @"link.netless.error.serialization.response";
NSString * const NETPPTOperationFailingURLResponseErrorKey = @"link.netless.serialization.response.error.response";

@implementation NETPPTDownloader

- (instancetype)initWithDir:(NSURL *)directory {
    if (self = [super init]) {
        _directory = directory;
        _fileManager = [[NETFileHandler alloc] initWithDirectory:directory.absoluteString];
        _downloadSlideIndex = 1;
    }
    return self;
}

// for unitTest
- (void)prepareDownload:(NSString *)uuid slideIndex:(NSInteger)slideIndex {
    if (![self.downloader.uuid isEqualToString:uuid]) {
        [self.downloader invalidateAndCancel];
    }
    self.downloadSlideIndex = slideIndex;
    self.slideIndex = slideIndex;
    self.downloader = [[NETDownloader alloc] initWithUUID:uuid];
    [self startDownload];
}

- (void)updateUUID:(NSString *)uuid slideIndex:(NSInteger)slideIndex baseURL:(NSURL *)baseURL {
    BOOL sameUUID = [self.downloader.uuid isEqualToString:uuid];

    if (sameUUID && slideIndex == self.downloadSlideIndex && [baseURL.absoluteString isEqualToString:self.downloader.baseURL.absoluteString]) {
        return;
    }
    
    // cancel resource download when downloader is downloading resource file and the file is not next slide needed
    if (self.downloadSlideIndex != slideIndex && self.resourceName && [self inNextSlide:self.resourceName] != -1) {
        [self.downloader cancelCurrentResource];
    }
    
    self.resourceName = nil;
    self.downloadSlideIndex = slideIndex;
    self.slideIndex = slideIndex;

    if (!sameUUID) {
        // cancel all download, start new downloader
        [self.downloader invalidateAndCancel];
        self.downloader = [[NETDownloader alloc] initWithUUID:uuid baseURL:baseURL];
        self.downloader.downloadRecord = [[self.fileManager downloadRecord:uuid] mutableCopy];
        self.finish = NO;
        [self startDownload];
    } else if (self.isFinished) {
        // just restart download
        self.finish = NO;
        [self startDownload];
    }
}

- (void)downloadPublicZipIfNotExist {
    if ([self.fileManager isPublicFilesExist]) {
        return;
    }
    NETDownloader *downloader = [[NETDownloader alloc] initWithUUID:@""];
    __weak typeof(self)weakSelf = self;
    [downloader downloadPublicZip:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
            [weakSelf.fileManager unzip:location toDestination:[weakSelf.fileManager publicFilesDir]];
        } else if (!error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL],
                                       NETPPTOperationFailingURLResponseErrorKey: urlResponse};
            error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        }
        if ([weakSelf.delegate respondsToSelector:@selector(downloadPublicZip:)]) {
            [weakSelf.delegate downloadPublicZip:error];
        }
    }];
}

- (void)setupDownloadFilesInfo:(NSString *)uuid {
    NSData *data = [NSData dataWithContentsOfURL:[self.fileManager bigFile:uuid]];
    if (data && [self.downloader.uuid isEqualToString:uuid]) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.downloader.filesInfo = json;
    }
}

#pragma mark - ppt download
- (void)startDownload {
    NSString *uuid = self.downloader.uuid;
    
    if ([self.fileManager isPresentationFinishDownload:uuid]) {
        [self setupDownloadFilesInfo:uuid];
        [self downloadNextSlide];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    [self.downloader downloadPresentationZip:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"download Presentation location:%@ response:%@ error:%@", location.absoluteString, response, [error description]);
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
            [weakSelf.fileManager unzip:location toUUID:uuid];
            [weakSelf setupDownloadFilesInfo:uuid];
        } else if (!error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL],
                                       NETPPTOperationFailingURLResponseErrorKey: urlResponse};
            error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        }
        
        if ([weakSelf.delegate respondsToSelector:@selector(downloadPresentationZip:error:)]) {
            [weakSelf.delegate downloadPresentationZip:uuid error:error];
        }
        [weakSelf downloadNextSlide];
    }];
}

- (void)downloadNextSlide
{
    NSInteger nextSlideIndex = self.downloadSlideIndex + 1;
    NSString *uuid = self.downloader.uuid;

    if (nextSlideIndex > [self.fileManager slideCount:uuid]) {
        NSLog(@"finish at SlideIndex: %ld", nextSlideIndex - 1);
        self.downloadSlideIndex = self.slideIndex;
        [self downloadShareResource:nil];
        return;
    } else if ([self.downloader isSlideZipFinishDownload:uuid slideIndex:nextSlideIndex]) {
        NSLog(@"slideIndex: %ld is already download", nextSlideIndex - 1);
        self.downloadSlideIndex += 1;
        [self downloadNextSlide];
        return;
    }

    __weak typeof(self)weakSelf = self;
    [self.downloader downloadSlideResource:nextSlideIndex completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"download slide location:%@ response:%@", location.absoluteString, response);
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
            [weakSelf.fileManager unzip:location toUUID:uuid];
            [weakSelf.downloader registerSlideResource:uuid slideIndex:nextSlideIndex];
            [weakSelf.fileManager writeRecord:weakSelf.downloader.downloadRecord toUUID:uuid];
        } else if (!error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL],
                                       NETPPTOperationFailingURLResponseErrorKey: urlResponse};

            error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        }
        if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
            [weakSelf.delegate downloadSlideZip:uuid index:nextSlideIndex error:error];
        }
        if (weakSelf.downloadSlideIndex == nextSlideIndex) {
            weakSelf.downloadSlideIndex += 1;
            [weakSelf downloadNextSlide];
        } else {
            [weakSelf downloadNextSlide];
        }
    }];
}

/**
 * if not in slide, return -1 not NSNotFound for convenience
 */
- (NSInteger)inNextSlide:(NSString *)name {
    
    NSInteger nextSlideIndex = self.downloadSlideIndex + 1;
    NSString *slideIndexKey = [NSString stringWithFormat:@"%ld", (long)nextSlideIndex];
    NSArray<NSDictionary *> *list = self.downloader.filesInfo[slideIndexKey];

    NSInteger __block index = -1;
    [list enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"name"] isEqualToString:name]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (void)downloadShareResource:(NSString * _Nullable)lastName {
    
    NSInteger nextSlideIndex = self.downloadSlideIndex + 1;
    NSString *uuid = self.downloader.uuid;
    
    if (nextSlideIndex > [self.fileManager slideCount:uuid]) {
        self.finish = YES;
        NSLog(@"resource download share resource finish: %ld", nextSlideIndex);
        return;
    }

    if (![self.downloader isSlideZipFinishDownload:uuid slideIndex:nextSlideIndex]) {
        NSLog(@"resource back to download next slide resource index: %ld", nextSlideIndex);
        [self downloadNextSlide];
        return;
    }
    
    if (!self.downloader.filesInfo) {
        NSLog(@"resource stop download because no download files info");
        return;
    }
    
    NSString *slideIndexKey = [NSString stringWithFormat:@"%ld", (long)nextSlideIndex];
    NSArray<NSDictionary *> *list = self.downloader.filesInfo[slideIndexKey];

    NSInteger index = [self inNextSlide:lastName];
    
    NSInteger nextResourceIndex = index + 1;
    NSString *name;
    if ([list count] > nextResourceIndex) {
        name = list[nextResourceIndex][@"name"];
    }
    if (!name) {
        NSLog(@"resource download next slide: %ld", (long)self.downloadSlideIndex);
        self.downloadSlideIndex += 1;
        [self downloadShareResource:nil];
        return;
    }
    
    if ([self.fileManager isFileExistIn:uuid name:name]) {
        NSLog(@"download next resource in slide: %ld", self.downloadSlideIndex);
        [self downloadShareResource:name];
        return;
    }

    self.resourceName = name;
    __weak typeof(self)weakSelf = self;
    [self.downloader downloadResource:name completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"download resource location:%@ response:%@", location.absoluteString, response);

        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) {
            NSURL *fileURL = [weakSelf.fileManager fileIn:uuid name:name];
            [NETFileHandler copyItemAtURL:location toURL:fileURL error:nil];
            if ([weakSelf.delegate respondsToSelector:@selector(downloadShareResource:index:name:error:)]) {
                [weakSelf.delegate downloadShareResource:uuid index:nextSlideIndex name:name error:nil];
            }
        } else if ([weakSelf.delegate respondsToSelector:@selector(downloadSlideZip:index:error:)]) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"NETPPTDownloader", nil), [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode],   (long)urlResponse.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL],
                                       NETPPTOperationFailingURLResponseErrorKey: urlResponse};

            error = [NSError errorWithDomain:NETPPTResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        }
        if ([weakSelf.delegate respondsToSelector:@selector(downloadShareResource:index:name:error:)]) {
            [weakSelf.delegate downloadShareResource:uuid index:nextSlideIndex name:name error:error];
        }

        [weakSelf downloadShareResource:name];
    }];
}

#pragma mark -

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

#pragma mark -

- (NSString *)directorySize {
    return [self.fileManager directorySize];
}
@end
