//
//  AppDelegate.h
//  MongoDB
//
//  Created by diRex on 3/17/14.
//  Copyright (c) 2014 https://www.mongodb.org/. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSStatusItem *statusBar;
    IBOutlet NSMenu *statusMenu;
    
    NSStatusItem *statusItem;
    NSImage *statusImage;
}

- (IBAction)openDoc:(id)sender;

@end
