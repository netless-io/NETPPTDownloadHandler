//
//  NETFileHandler.m
//  NETZipDownloadHandler
//
//  Created by yleaf on 2021/6/26.
//

#import "NETFileHandler.h"
#import <SSZipArchive/SSZipArchive.h>

@interface NSFileManager (NETFileDownloader)
- (BOOL)net_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error;
@end

@interface NETFileHandler ()
@property (nonatomic, copy, readwrite) NSString *directory;
@end


static NSString *kSlideDownloadJSON = @"slideDownload.json";
@implementation NETFileHandler

+ (BOOL)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError **)error
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSError *fileError = nil;
    
    if ([defaultManager fileExistsAtPath:dstURL.path]) {
        [defaultManager removeItemAtURL:dstURL error:&fileError];
    }

    if (fileError) {
        *error = fileError;
        return NO;
    }
    
    NSURL *directoryURL = [dstURL URLByDeletingLastPathComponent];
    if (![defaultManager fileExistsAtPath:directoryURL.absoluteString]) {
        BOOL result = [self createDirectory:directoryURL error:&fileError];
        if (!result) {
            *error = fileError;
            return result;
        }
    }
    
    return [defaultManager moveItemAtURL:srcURL toURL:dstURL error:error];
}

+ (BOOL)createDirectory:(NSURL *)path error:(NSError **)error
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    return [defaultManager createDirectoryAtURL:path withIntermediateDirectories:YES attributes:@{} error:error];
}



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

- (NSURL *)baseDirURL {
    return [NSURL fileURLWithPath:self.directory isDirectory:YES];
}

- (NSURL *)publicFilesDir
{
    return [NSURL fileURLWithPath:@"publicFiles" isDirectory:YES relativeToURL:[self baseDirURL]];
}

- (NSURL *)uuidDirectory:(NSString *)uuid {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"dynamicConvert/%@", uuid] isDirectory:YES relativeToURL:[self baseDirURL]];
}

- (NSURL *)bigFile:(NSString *)uuid {
    return [NSURL fileURLWithPath:@"bigFile.json" isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
}

- (NSURL *)infoJSON:(NSString *)uuid {
    return [NSURL fileURLWithPath:@"info.json" isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
}

- (NSURL *)fileIn:(NSString *)uuid name:(NSString *)name {
    return [NSURL fileURLWithPath:name isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
}

#pragma mark - PPT

- (BOOL)isPublicFilesExist {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self publicFilesDir].path];
}

- (BOOL)isPresentationFinishDownload:(NSString *)uuid {
    // can not check zip or all files, so just check share.json
    return [[NSFileManager defaultManager] fileExistsAtPath:[self bigFile:uuid].path];
}

- (BOOL)hasBigFileJSON:(NSString *)uuid {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self bigFile:uuid].path];
}

- (BOOL)isFileExistIn:(NSString *)uuid name:(NSString *)name {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self fileIn:uuid name:name].path];
}

- (BOOL)isSlideZipFinishDownload:(NSString *)uuid slideIndex:(NSInteger)slideIndex
{
    NSURL *fileURL = [NSURL fileURLWithPath:kSlideDownloadJSON isDirectory:NO relativeToURL:[self uuidDirectory:uuid]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSString *slideKey = [NSString stringWithFormat:@"%ld", slideIndex];

        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        return [json[slideKey][@"success"] boolValue];
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
        NSDictionary *json = @{slideKey: @{@"success": @YES}};
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        [data writeToFile:fileURL.path atomically:YES];
    }
}

- (BOOL)unzip:(NSURL *)zip toDestination:(NSURL *)url {
    return [SSZipArchive unzipFileAtPath:zip.path toDestination:url.path overwrite:YES password:nil error:nil];
}

- (BOOL)unzip:(NSURL *)zip toUUID:(NSString *)uuid {
    return [SSZipArchive unzipFileAtPath:zip.path toDestination:[self uuidDirectory:uuid].path overwrite:NO password:nil error:nil];
}

- (NSInteger)slideCount:(NSString *)uuid {
    NSURL *fileURL = [self infoJSON:uuid];
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

- (NSString *)directorySize {
    NSByteCountFormatter *sizeFormatter = [[NSByteCountFormatter alloc] init];
    unsigned long long allocatedSize;
    [[NSFileManager defaultManager] net_getAllocatedSize:&allocatedSize
                                       ofDirectoryAtURL:[NSURL fileURLWithPath:self.directory]
                                                  error:NULL];
    NSString *size = [sizeFormatter stringFromByteCount:allocatedSize];
    return size;
}

@end

@implementation NSFileManager (NETFileManager)
// https://stackoverflow.com/a/28660040/4770006
// This method calculates the accumulated size of a directory on the volume in bytes.
//
// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
// that would become available on the volume if the directory would be deleted.
//
// Caveat: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
// directories, hard links, ...).

- (BOOL)net_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(size != NULL);
    NSParameterAssert(directoryURL != nil);

    // We'll sum up content size here:
    unsigned long long accumulatedSize = 0;

    // prefetching some properties during traversal will speed up things a bit.
    NSArray *prefetchedProperties = @[
        NSURLIsRegularFileKey,
        NSURLFileAllocatedSizeKey,
        NSURLTotalFileAllocatedSizeKey,
    ];

    // The error handler simply signals errors to outside code.
    __block BOOL errorDidOccur = NO;
    BOOL (^errorHandler)(NSURL *, NSError *) = ^(NSURL *url, NSError *localError) {
        if (error != NULL)
            *error = localError;
        errorDidOccur = YES;
        return NO;
    };

    // We have to enumerate all directory contents, including subdirectories.
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                             includingPropertiesForKeys:prefetchedProperties
                                                                                options:(NSDirectoryEnumerationOptions)0
                                                                           errorHandler:errorHandler];

    // Start the traversal:
    for (NSURL *contentItemURL in enumerator) {

        // Bail out on errors from the errorHandler.
        if (errorDidOccur)
            return NO;

        // Get the type of this item, making sure we only sum up sizes of regular files.
        NSNumber *isRegularFile;
        if (! [contentItemURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:error])
            return NO;
        if (! [isRegularFile boolValue])
            continue; // Ignore anything except regular files.

        // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
        // This includes metadata, compression (on file system level) and block size.
        NSNumber *fileSize;
        if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:error])
            return NO;

        // In case the value is unavailable we use the fallback value (excluding meta data and compression)
        // This value should always be available.
        if (fileSize == nil) {
            if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLFileAllocatedSizeKey error:error])
                return NO;

            NSAssert(fileSize != nil, @"huh? NSURLFileAllocatedSizeKey should always return a value");
        }

        // We're good, add up the value.
        accumulatedSize += [fileSize unsignedLongLongValue];
    }

    // Bail out on errors from the errorHandler.
    if (errorDidOccur)
        return NO;

    // We finally got it.
    *size = accumulatedSize;
    return YES;
}

@end

