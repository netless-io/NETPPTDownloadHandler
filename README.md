# NETPPTDownloadHandler

[![CI Status](https://img.shields.io/travis/11785335/NETPPTDownloadHandler.svg?style=flat)](https://travis-ci.org/11785335/NETPPTDownloadHandler)
[![Version](https://img.shields.io/cocoapods/v/NETPPTDownloadHandler.svg?style=flat)](https://cocoapods.org/pods/NETPPTDownloadHandler)
[![License](https://img.shields.io/cocoapods/l/NETPPTDownloadHandler.svg?style=flat)](https://cocoapods.org/pods/NETPPTDownloadHandler)
[![Platform](https://img.shields.io/cocoapods/p/NETPPTDownloadHandler.svg?style=flat)](https://cocoapods.org/pods/NETPPTDownloadHandler)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

NETPPTDownloadHandler is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NETPPTDownloadHandler'
```

## how to use

### download ppt zips

1. create NETPPTDownloadHandler instance, pass directory which store ppt files.
2. call NETPPTDownloadHandler's onRoomState method when joinRoom and roomStateChange. 

```Objective-C
...
NETPPTDownloadHandler *pptDownloader = [[NETPPTDownloadHandler alloc] initWithDir:NSTemporaryDirectory()];
[whiteSDK joinRoomWithUuid:@"uuid" roomToken:@"roomToken" completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
    [pptDownloader onRoomState(room.state)];
}];

...
- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState {
    [pptDownloader onRoomState(modifyState)];
}

```

## License

NETPPTDownloadHandler is available under the MIT license. See the LICENSE file for more info.

# 中文

## 介绍

用于下载 whiteboard 库中，动态 ppt 的资源。目前该库仅支持下载分页 ppt zip 包。
如果能够提前下载资源，建议下载完整 zip 包进行存储，而不是下载分页 zip。

## 使用方式

`onRoomState`方法：会手动读取传入的 roomState 方法，读取当页的 ppt 内容，如果存在动态 ppt，则会提取 其中 ppt 的 taskUUID，开始下载下一页的 zip 包资源。当下一页下载完成后，会继续下载后续的 zip 包分页。

1. 初始化 NETPPTDownloadHandler，配置存储位置
2. 在 Room 初始化后调用 NETPPTDownloadHandler 的 onRoomState 方法。
3. 在 Room 的 fireRoomStateChanged 也同时调用 onRoomState 方法，使其在翻页后，下载下一页内容。

```Objective-C
...
NETPPTDownloadHandler *pptDownloader = [[NETPPTDownloadHandler alloc] initWithDir:NSTemporaryDirectory()];
[whiteSDK joinRoomWithUuid:@"uuid" roomToken:@"roomToken" completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
    [pptDownloader onRoomState(room.state)];
}];

...
- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState {
    [pptDownloader onRoomState(modifyState)];
}
```

## TODO 

- [ ] 分页下载的顺序与完整数量，从 从 taskUUID 下载的内容里读取，更改为 sceneState 中提取。
- [ ] 提供控制下载后续多少页的逻辑。
- [ ] 提供重新开始逻辑。
