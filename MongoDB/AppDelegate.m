//
//  AppDelegate.m
//  MongoDB
//
//  Created by diRex on 3/17/14.
//  Copyright (c) 2014 https://www.mongodb.org/. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void) awakeFromNib {
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSBundle *bundle = [NSBundle mainBundle];
    
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"mongo_db" ofType:@"png"]];
    
    [statusItem setImage:statusImage];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:true];
    
}

- (IBAction)openDoc:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://docs.mongodb.org/manual/"];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
        NSLog(@"Failed to open url: %@",[url description]);
}

@end
