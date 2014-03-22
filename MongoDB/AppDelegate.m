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
    NSLog( @"Init" );
    [self launchMongoDB];
}
-(void) applicationWillTerminate:(NSNotification *)notification{
    NSLog( @"END" );
    [self stop];
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
- (void) launchMongoDB {
    [self setInitParams];
    
	in = [[NSPipe alloc] init];
	out = [[NSPipe alloc] init];
	task = [[NSTask alloc] init];
    
    startTime = time(NULL);
    
    NSMutableString *launchPath = [[NSMutableString alloc] init];
	[launchPath appendString:[[NSBundle mainBundle] resourcePath]];
	[launchPath appendString:@"/mongodb-core"];
	[task setCurrentDirectoryPath:launchPath];
    
    NSLog(launchPath);
    [launchPath appendString:@"/bin/mongod"];
    
	[task setLaunchPath:launchPath];
    
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

-(IBAction)stop:(id)sender{
    NSLog(@"STOP");
    [task terminate];
}


- (NSURL *)applicationSupportFolder {
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSFileManager*fm = [NSFileManager defaultManager];
    NSURL*    dirPath = nil;
    
    // Find the application support directory in the home directory.
    NSArray* appSupportDir = [fm URLsForDirectory:NSApplicationSupportDirectory
                                        inDomains:NSUserDomainMask];
    if ([appSupportDir count] > 0)
    {
        // Append the bundle ID to the URL for the
        // Application Support directory
        dirPath = [[appSupportDir objectAtIndex:0] URLByAppendingPathComponent:bundleID];
        
        // If the directory does not exist, this method creates it.
        // This method call works in OS X 10.7 and later only.
        NSError*    theError = nil;
        if (![fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES
                           attributes:nil error:&theError])
        {
            // Handle the error.
            
            return nil;
        }
    }
    
    return dirPath;
    
}


- (void)createDiretory:(NSURL *)dir fileManager:(NSFileManager *)fileManager {
    NSError *err;
    if(![fileManager fileExistsAtPath:[dir path]]){
        [fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err];
    }
    if (err) {
        NSLog(@"error create directory %@", err);
    }
}

- (void)createFile:(NSURL *)file fileManager:(NSFileManager *)fileManager {
    NSString *path = [file path];
    if(![fileManager fileExistsAtPath:path]){
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }
}

-(void)setInitParams {
    NSFileManager* fileManager = [NSFileManager defaultManager];
	// determine data dir
	NSURL *dataDir = [self applicationSupportFolder];
    
    NSLog(@"dataDir URL: %@",dataDir);
    // database and views dir
    NSURL *dbDir = [dataDir URLByAppendingPathComponent:@"data/db"];
     NSLog(@"dbDir URL: %@",dbDir);
    
	[self createDiretory:dbDir fileManager:fileManager];
    
    // config dir
    NSURL *confDir = [dataDir URLByAppendingPathComponent:@"etc"];
    NSLog(@"confDir URL: %@",confDir);
    
    [self createDiretory:confDir fileManager:fileManager];
    
    NSURL *confFile = [confDir URLByAppendingPathComponent:@"mongodb.conf"];
    NSLog(@"confFile URL: %@",confFile);
    
   // [self createFile:confFile fileManager:fileManager];
    
   
    
    NSDictionary* confDict = [NSDictionary dictionaryWithContentsOfURL:confFile];
    
        [confDict setValue:dbDir forKey:@"dbpath"];
    
    [confDict writeToURL:confFile atomically:YES];
}



@end
