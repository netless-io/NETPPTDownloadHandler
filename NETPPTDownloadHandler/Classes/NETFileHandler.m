//
//  NETFileHandler.m
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/26.
//

#import "NETFileHandler.h"
#import <SSZipArchive/SSZipArchive.h>

@interface NETFileHandler ()

@property (nonatomic, copy, readwrite) NSString *directory;

@end


static NSString *kSlideDownloadJSON = @"slideDownload.json";
@implementation NETFileHandler

#pragma mark -
#pragma mark - Instance Methods
#pragma mark -

- (instancetype)initWithDirectory:(NSString *)dir {
    if (self = [super init]) {
        _directory = dir;
    }
    return self;
}

#pragma mark - FileURL

- (NSURL *)baseFileURL {
    return [NSURL fileURLWithPath:self.directory isDirectory:YES];
}

- (NSURL *)publicFilesDirectory
{
    return [NSURL fileURLWithPath:@"publicFiles" isDirectory:YES relativeToURL:[self baseFileURL]];
}

- (NSURL *)uuidDirectory:(NSString *)uuid {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"dynamicConvert/%@", uuid] isDirectory:YES relativeToURL:[self baseFileURL]];
}

- (NSURL *)shareJSONFile:(NSString *)uuid {
    return [NSURL fileURLWithPath:@"share.json" isDirectory:YES relativeToURL:[self uuidDirectory:uuid]];
}

- (NSURL *)infoJSONFile:(NSString *)uuid {
    return [NSURL fileURLWithPath:@"info.json" isDirectory:YES relativeToURL:[self uuidDirectory:uuid]];
}

#pragma mark - PPT

- (BOOL)isPublicFilesExist {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self publicFilesDirectory].path];
}

- (BOOL)isPresentationExist:(NSString *)uuid {
    // can not check zip or all files, so just check share.json
    return [[NSFileManager defaultManager] fileExistsAtPath:[self shareJSONFile:uuid].path];
}

- (BOOL)isShareJSONExist:(NSString *)uuid {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self shareJSONFile:uuid].path];
}

- (BOOL)isSlideResourceZipFinish:(NSString *)uuid slideIndex:(NSInteger)slideIndex
{
    NSURL *fileURL = [NSURL fileURLWithPath:kSlideDownloadJSON isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSString *slideKey = [NSString stringWithFormat:@"%ld", slideIndex];

        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        return [json[slideKey] boolValue];
    } else {
        return NO;
    }
}

- (void)registerSlideResource:(NSString *)uuid slideIndex:(NSInteger)slideIndex
{
    NSURL *fileURL = [NSURL fileURLWithPath:kSlideDownloadJSON isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
    NSString *slideKey = [NSString stringWithFormat:@"%ld", slideIndex];

    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        NSError *error = nil;
        NSMutableDictionary *json = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] mutableCopy];
        json[slideKey] = @(YES);
        data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        [data writeToFile:fileURL.path atomically:YES];
    } else {
        NSDictionary *json = @{slideKey: @YES};
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        [data writeToFile:fileURL.path atomically:YES];
    }
}

- (BOOL)unzipPptZip:(NSURL *)zip uuid:(NSString *)uuid {
    BOOL result = [SSZipArchive unzipFileAtPath:zip.path toDestination:[self uuidDirectory:uuid].path overwrite:NO password:nil error:nil];
    return result;
}

- (NSInteger)slideCount:(NSString *)uuid {
    NSURL *fileURL = [self infoJSONFile:uuid];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    if (data && !error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (json[@"totalPageSize"]) {
            return [json[@"totalPageSize"] integerValue];
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

@end
