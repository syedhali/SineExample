//
//  AppDelegate.m
//  SineExample
//
//  Created by Syed Haris Ali on 7/2/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.controller = [[PlayFileViewController alloc] init];
    self.controller.view.frame = [self.window.contentView frame];
    self.controller.view.autoresizingMask = (NSViewWidthSizable|NSViewHeightSizable);
    [self.window.contentView addSubview:self.controller.view];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
    
}

@end
