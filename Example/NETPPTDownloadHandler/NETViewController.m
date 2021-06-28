//
//  NETViewController.m
//  NETPPTDownloadHandler
//
//  Created by 11785335 on 06/27/2021.
//  Copyright (c) 2021 11785335. All rights reserved.
//

#import "NETViewController.h"
#import <NETPPTDownloadHandler/NETPPTDownloader.h>
@interface NETViewController ()
@property (nonatomic, strong) NETPPTDownloader *pptDownloader;
@end

@implementation NETViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.pptDownloader = [[NETPPTDownloader alloc] initWithDir:[NSURL URLWithString:NSTemporaryDirectory()]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
