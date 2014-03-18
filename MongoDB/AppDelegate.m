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

- (void)windowWillClose:(NSNotification *)aNotification {
    NSLog(@"STOP");
    [self stop];
}

- (void) awakeFromNib {
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSBundle *bundle = [NSBundle mainBundle];
    
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"mongo_db" ofType:@"png"]];
    
    [statusItem setImage:statusImage];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:true];
    [self launchMongoDB];
}

- (IBAction)openDoc:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://docs.mongodb.org/manual/"];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
        NSLog(@"Failed to open url: %@",[url description]);
}
- (void) launchMongoDB {
    //[self setInitParams];
    
	in = [[NSPipe alloc] init];
	out = [[NSPipe alloc] init];
	task = [[NSTask alloc] init];
    
    startTime = time(NULL);
    
    NSMutableString *launchPath = [[NSMutableString alloc] init];
	[launchPath appendString:[[NSBundle mainBundle] resourcePath]];
	[launchPath appendString:@"/mongodbx-core"];
	//[task setCurrentDirectoryPath:launchPath];
    
    NSLog(launchPath);
   
	[task setLaunchPath:@"/usr/local/mongodb/bin/mongod"];
    
	[task setStandardInput:in];
	[task setStandardOutput:out];
    
	NSFileHandle *fh = [out fileHandleForReading];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
    
	[nc addObserver:self
           selector:@selector(dataReady:)
               name:NSFileHandleReadCompletionNotification
             object:fh];
	
	[nc addObserver:self
           selector:@selector(taskTerminated:)
               name:NSTaskDidTerminateNotification
             object:task];
    
  	[task launch];
  	[fh readInBackgroundAndNotify];
}



-(void)flushLog {
    fflush(logFile);
}
-(void)taskTerminated:(NSNotification *)note{
    [self cleanup];
    /*[self logMessage: [NSString stringWithFormat:@"Terminated with status %d\n",
                       [[note object] terminationStatus]]];*/
    
    time_t now = time(NULL);
    if (now - startTime < MIN_LIFETIME) {
        NSInteger b = NSRunAlertPanel(@"Problem Running MongoDB",
                                      @"MongoDB Server doesn't seem to be operating properly.  "
                                      @"Check Console logs for more details.", @"Retry", @"Quit", nil);
        if (b == NSAlertAlternateReturn) {
            [NSApp terminate:self];
        }
    }
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(launchMongoDB) userInfo:nil repeats:NO];
}
- (void)dataReady:(NSNotification *)n{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if ([d length]) {
        [self appendData:d];
    }
    if (task)
        [[out fileHandleForReading] readInBackgroundAndNotify];
}


- (void)appendData:(NSData *)d {
    NSString *s = [[NSString alloc] initWithData: d
                                        encoding: NSUTF8StringEncoding];
    
     }

-(void)cleanup{
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)stop{
    [task terminate];
}

-(void) teste {
    NSTask *task2;
    task2 = [[NSTask alloc] init];
    [task2 setLaunchPath: @"/usr/local/mongodb/bin/mongod"];
    
    /*NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"foo", @"bar.txt", nil];
    [task2 setArguments: arguments];*/
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task2 setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task2 launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", string);
    
  
}


@end
