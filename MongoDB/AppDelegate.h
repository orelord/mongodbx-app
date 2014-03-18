//
//  AppDelegate.h
//  MongoDB
//
//  Created by diRex on 3/17/14.
//  Copyright (c) 2014 https://www.mongodb.org/. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define MIN_LIFETIME 10


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSStatusItem *statusBar;
    IBOutlet NSMenu *statusMenu;
    
    NSStatusItem *statusItem;
    NSImage *statusImage;
    
    NSTask *task;
    NSPipe *in, *out;
    FILE *logFile;
    time_t startTime;
    
    NSString *logPath;
}

- (IBAction)openDoc:(id)sender;
- (void)launchMongoDB;

- (IBAction)stop:(id)sender;

- (void)stop;
@end
