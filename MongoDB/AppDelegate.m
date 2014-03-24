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
    NSDictionary *params = [self setInitParams];
    
	in = [[NSPipe alloc] init];
	out = [[NSPipe alloc] init];
	task = [[NSTask alloc] init];
    
    startTime = time(NULL);
    
    NSMutableString *launchPath = [[NSMutableString alloc] init];
	[launchPath appendString:[[NSBundle mainBundle] resourcePath]];
	[launchPath appendString:@"/mongodb-core"];
	[task setCurrentDirectoryPath:launchPath];
  
    [launchPath appendString:@"/bin/mongod"];
    NSLog(@"launchPath: %@", launchPath);
	[task setLaunchPath:launchPath];
    
    
    NSMutableArray *args =  [[NSMutableArray alloc]init];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *param = [@"--" stringByAppendingString:key];
        [args addObject: param];
        [args addObject: obj];

    }];
    
    NSLog(@"params: %@ \n\n", args);

    [task setArguments:args];
    
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
    NSLog( [NSString stringWithFormat:@"Terminated with status %d\n",
             [[note object] terminationStatus]]);
    
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
    
    NSLog(s);
    
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

- (BOOL)createFile:(NSURL *)file fileManager:(NSFileManager *)fileManager {
    NSString *path = [file path];
    if(![fileManager fileExistsAtPath:path]){
        [fileManager createFileAtPath:path contents:nil attributes:nil];
        return YES;
    }
    return NO;
}

-(NSDictionary *)setInitParams {
    NSFileManager* fileManager = [NSFileManager defaultManager];
	
	NSURL *dataDir = [self applicationSupportFolder];
   
    NSURL *dbDir = [dataDir URLByAppendingPathComponent:@"data/db"];
    [self createDiretory:dbDir fileManager:fileManager];
    
    
    NSURL *confDir = [dataDir URLByAppendingPathComponent:@"etc"];
    
   
    
    [self createDiretory:confDir fileManager:fileManager];
    
    NSURL *confFile = [confDir URLByAppendingPathComponent:@"mongodb.conf"];
    
    NSMutableDictionary *params  = nil;
    if (![fileManager fileExistsAtPath:[confFile path]]){
        params = [[NSMutableDictionary alloc] init];
        
        [params setObject:[dbDir path] forKey:@"dbpath"];
        [params setObject:@"27017" forKey:@"port"];
        
        [params writeToURL:confFile atomically:YES];
    }else{
        params = [[NSMutableDictionary alloc] initWithContentsOfURL:confFile];
    }
    
    
    return params;
    
}

@end
