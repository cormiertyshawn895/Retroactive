//
//  File: ProcessMonitor.m
//  Project: Proc Info
//
//  Created by: Patrick Wardle
//  Copyright:  2017 Objective-See
//  License:    Creative Commons Attribution-NonCommercial 4.0 International License
//

//disable incomplete/umbrella warnings
// otherwise complains about 'audit_kevents.h'
#pragma clang diagnostic ignored "-Wincomplete-umbrella"

#import "Consts.h"
#import "procInfo.h"
#import "Utilities.h"

#import <unistd.h>
#import <libproc.h>
#import <pthread.h>
#import <bsm/audit.h>
#import <sys/ioctl.h>
#import <sys/types.h>
#import <bsm/libbsm.h>
#import <Cocoa/Cocoa.h>
#import <bsm/audit_kevents.h>
#import <security/audit/audit_ioctl.h>

@interface ProcInfo()

/* INSTANCE VARIABLES */

//skip CPU-intensive logic
@property BOOL goEasy;

//callback block
@property(nonatomic, copy)ProcessCallbackBlock processCallback;

//stop flag
@property BOOL shouldStop;

@end

@implementation ProcInfo

//init
// just check OS version
-(id _Nullable)init
{
    //super
    self = [super init];
    if(self)
    {
        //make sure OS is supported
        // for now, OS X 10.8+ though could be earlier?
        if(YES != PI_isSupportedOS())
        {
            //err msg
            NSLog(@"ERROR: %@ is not a supported OS", PI_getOSVersion());
            
            //unset
            self = nil;
            
            //bail
            goto bail;
        }
    }
    
bail:
    
    return self;
}

//init w/ flag
// flag dictates if CPU-intensive logic (code signing, etc) should be preformed
-(id _Nullable)init:(BOOL)goEasy;
{
    //init
    // calls 'super' too
    self = [self init];
    if(self)
    {
        //save mode
        self.goEasy = goEasy;
    }
    
bail:
    
    return self;
}

//start monitoring
// note: requires root/macOS 10.12.4+ for full monitoring
-(void)start:(ProcessCallbackBlock)callback
{
    //OS version info
    NSDictionary* osVersionInfo = nil;
    
    //save
    self.processCallback = callback;
    
    //get OS version info
    osVersionInfo = PI_getOSVersion();

    //do basic (app) monitoring
    // if not root, or OS version is < 10.12.4 (due to kernel bug)
    if( (0 != getuid()) ||
        ([osVersionInfo[@"minorVersion"] intValue] < OS_MINOR_VERSION_SIERRA) ||
        (([osVersionInfo[@"minorVersion"] intValue] == OS_MINOR_VERSION_SIERRA) && ([osVersionInfo[@"bugfixVersion"] intValue] < 4)) )
    {
        //setup app monitoring
        [self appMonitor];
    }
    
    //otherwise, enable full monitoring
    else
    {
        //start process monitoring via openBSM to get apps & procs
        // sits in while(YES) loop, so we invoke call in a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //monitor
            [self monitor];
            
        });
    }

    return;
}

//stop monitoring
-(void)stop
{
    //stop app monitoring
    // can always call, even if we didn't setup app monitor
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    //set 'stop' monitor bool
    // is checked in 'monitor' method as termination condition
    self.shouldStop = YES;
    
    return;
}

//monitor for new process events
-(void)monitor
{
    //event mask
    // what event classes to watch for
    u_int eventClasses = AUDIT_CLASS_EXEC | AUDIT_CLASS_PROCESS;
    
    //file pointer to audit pipe
    FILE* auditFile = NULL;
    
    //file descriptor for audit pipe
    int auditFileDescriptor = -1;
    
    //status var
    int status = -1;
    
    //preselect mode
    int mode = -1;
    
    //queue length
    int maxQueueLength = -1;
    
    //record buffer
    u_char* recordBuffer = NULL;
    
    //token struct
    tokenstr_t tokenStruct = {0};
    
    //total length of record
    int recordLength = -1;
    
    //amount of record left to process
    int recordBalance = -1;
    
    //amount currently processed
    int processedLength = -1;
    
    //process record obj
    Process* process = nil;
    
    //last fork
    Process* lastFork = nil;
    
    //argument
    NSString* argument = nil;
    
    //open audit pipe for reading
    auditFile = fopen(AUDIT_PIPE, "r");
    if(auditFile == NULL)
    {
        #ifdef DEBUG
        
        //err msg
        NSLog(@"ERROR: failed to open audit pipe %s", AUDIT_PIPE);
        
        #endif
        
        //bail
        goto bail;
    }
    
    //grab file descriptor
    auditFileDescriptor = fileno(auditFile);
    
    //init mode
    mode = AUDITPIPE_PRESELECT_MODE_LOCAL;
    
    //set preselect mode
    status = ioctl(auditFileDescriptor, AUDITPIPE_SET_PRESELECT_MODE, &mode);
    if(-1 == status)
    {
        //bail
        goto bail;
    }
    
    //grab max queue length
    status = ioctl(auditFileDescriptor, AUDITPIPE_GET_QLIMIT_MAX, &maxQueueLength);
    if(-1 == status)
    {
        //bail
        goto bail;
    }
    
    //set queue length to max
    status = ioctl(auditFileDescriptor, AUDITPIPE_SET_QLIMIT, &maxQueueLength);
    if(-1 == status)
    {
        //bail
        goto bail;
        
    }
    
    //set preselect flags
    // event classes we're interested in
    status = ioctl(auditFileDescriptor, AUDITPIPE_SET_PRESELECT_FLAGS, &eventClasses);
    if(-1 == status)
    {
        //bail
        goto bail;
    }
    
    //set non-attributable flags
    // event classes we're interested in
    status = ioctl(auditFileDescriptor, AUDITPIPE_SET_PRESELECT_NAFLAGS, &eventClasses);
    if(-1 == status)
    {
        //bail
        goto bail;
    }
    
    //forever
    // read/parse/process audit records
    while(YES)
    {
        @autoreleasepool
        {
            
        //first check termination flag/condition
        if(YES == self.shouldStop)
        {
            //bail
            goto bail;
        }
        
        //reset process record object
        process = nil;
        
        //free prev buffer
        if(NULL != recordBuffer)
        {
            //free
            free(recordBuffer);
            
            //unset
            recordBuffer = NULL;
        }
        
        //read a single audit record
        // note: buffer is allocated by function, so must be freed when done
        recordLength = au_read_rec(auditFile, &recordBuffer);
        
        //sanity check
        if(-1 == recordLength)
        {
            //continue
            continue;
        }
        
        //init (remaining) balance to record's total length
        recordBalance = recordLength;
        
        //init processed length to start (zer0)
        processedLength = 0;
        
        //parse record
        // read all tokens/process
        while(0 != recordBalance)
        {
            //extract token
            // and sanity check
            if(-1  == au_fetch_tok(&tokenStruct, recordBuffer + processedLength, recordBalance))
            {
                //error
                // skip record
                break;
            }
            
            //ignore records that are not related to process exec'ing/spawning
            // gotta wait till we hit/capture a AUT_HEADER* though, as this has the event type
            if( (nil != process) &&
                (YES != [self shouldProcessRecord:process.type]) )
            {
                //bail
                // skips rest of record
                break;
            }
            
            //process token(s)
            // create Process object, etc
            switch(tokenStruct.id)
            {
                //handle start of record
                // grab event type, which allows us to ignore events not of interest
                case AUT_HEADER32:
                case AUT_HEADER32_EX:
                case AUT_HEADER64:
                case AUT_HEADER64_EX:
                {
                    //create a new process
                    process = [[Process alloc] init];
                    
                    //save type
                    process.type = tokenStruct.tt.hdr32.e_type;
                    
                    break;
                }
                    
                //path
                // note: this might be updated/replaced later (if it's '/dev/null', etc)
                case AUT_PATH:
                {
                    //save path
                    process.path = [NSString stringWithUTF8String:tokenStruct.tt.path.path];
                    
                    break;
                }
                    
                //subject
                //  extract/save pid || ppid
                //  all these cases can be treated as subj32 cuz only accessing initial members
                case AUT_SUBJECT32:
                case AUT_SUBJECT32_EX:
                case AUT_SUBJECT64:
                case AUT_SUBJECT64_EX:
                {
                    //SPAWN (pid/ppid)
                    // if there was an AUT_ARG32 (which always come first), that's the pid! so this will be the ppid
                    if(AUE_POSIX_SPAWN == process.type)
                    {
                        //no AUT_ARG32?
                        // set as pid, and try manually to get ppid
                        if(-1 == process.pid)
                        {
                            //set pid
                            process.pid = tokenStruct.tt.subj32.pid;
                            
                            //manually get parent
                            process.ppid = [Process getParentID:process.pid];
                        }
                        //pid already set (via AUT_ARG32)
                        // this then, is the ppid
                        else
                        {
                            //set ppid
                            process.ppid = tokenStruct.tt.subj32.pid;
                        }
                    }
                    
                    //FORK
                    // ppid (pid is in AUT_ARG32)
                    else if(AUE_FORK == process.type)
                    {
                        //set ppid
                        process.ppid = tokenStruct.tt.subj32.pid;
                    }
                    
                    //AUE_EXEC/VE & AUE_EXIT
                    // this is the pid
                    else
                    {
                        //save pid
                        process.pid = tokenStruct.tt.subj32.pid;
                        
                        //manually get parent
                        process.ppid = [Process getParentID:process.pid];
                    }
                    
                    //get effective user id
                    process.uid = tokenStruct.tt.subj32.euid;
                    
                    break;
                }
                    
                //args
                // SPAWN/FORK this is pid
                case AUT_ARG32:
                case AUT_ARG64:
                {
                    //save pid
                    if( (AUE_POSIX_SPAWN == process.type) ||
                        (AUE_FORK == process.type) )
                    {
                        //32bit
                        if(AUT_ARG32 == tokenStruct.id)
                        {
                            //save
                            process.pid = tokenStruct.tt.arg32.val;
                        }
                        //64bit
                        else
                        {
                            //save
                            process.pid = (pid_t)tokenStruct.tt.arg64.val;
                        }
                    }
                    
                    //FORK
                    // doesn't have token for path, so try manually find it now
                    if(AUE_FORK == process.type)
                    {
                        //set path
                        [process pathFromPid];
                    }
                    
                    break;
                }
                    
                //exec args
                // just save into args
                case AUT_EXEC_ARGS:
                {
                    //save args
                    for(int i = 0; i<tokenStruct.tt.execarg.count; i++)
                    {
                        //try create arg
                        // this sometimes fails, not sure why?
                        argument = [NSString stringWithUTF8String:tokenStruct.tt.execarg.text[i]];
                        if(nil == argument)
                        {
                            //next
                            continue;
                        }
                        
                        //add argument
                        [process.arguments addObject:argument];
                    }
                    
                    break;
                }
                    
                //exit
                // save status
                case AUT_EXIT:
                {
                    //save
                    process.exit = tokenStruct.tt.exit.status;
                    
                    break;
                }
                    
                //record trailer
                // end/save, etc
                case AUT_TRAILER:
                {
                    //end
                    if( (nil != process) &&
                        (YES == [self shouldProcessRecord:process.type]) )
                    {
                        //handle process exits
                        if(AUE_EXIT == process.type)
                        {
                            //handle
                            [self handleProcessExit:process];
                        }
                        
                        //handle process starts
                        else
                        {
                            //also try get process path
                            // this is the most 'trusted way' (since exec_args can change)
                            [process pathFromPid];
                            
                            //failed to get path at runtime
                            // if 'AUT_PATH' was something like '/dev/null' or '/dev/console' use arg[0]...yes this can be spoofed :/
                            if( ((0 == process.path.length) || (YES == [process.path hasPrefix:@"/dev/"])) &&
                                 (0 != process.arguments.count) )
                            {
                                //use arg[0]
                                process.path = process.arguments.firstObject;
                            }
                            
                            //save fork events
                            // this will have ppid that can be used for child events (exec/spawn, etc)
                            if(AUE_FORK == process.type)
                            {
                                //save
                                lastFork = process;
                            }
                            
                            //when we don't have a ppid
                            // see if there was a 'matching' fork() that has it (only for non AUE_FORK events)
                            else if( (-1 == process.ppid)  &&
                                     (lastFork.pid == process.pid) )
                            {
                                //update
                                process.ppid = lastFork.ppid;
                            }
                            
                            //handle new process
                            [self handleProcessStart:process];
                        }
                    }
                    
                    //unset
                    process = nil;
                    
                    break;
                }
                    
                    
                default:
                    ;
                    
            }//process token
            
            
            //add length of current token
            processedLength += tokenStruct.len;
            
            //subtract lenght of current token
            recordBalance -= tokenStruct.len;
        }
            
        }//autorelease
    
    } //while(YES)
    
bail:
    
    //free buffer
    if(NULL != recordBuffer)
    {
        //free
        free(recordBuffer);
        
        //unset
        recordBuffer = NULL;
    }
    
    //close audit pipe
    if(NULL != auditFile)
    {
        //close
        fclose(auditFile);
        
        //unset
        auditFile = NULL;
    }
    
    return;
}

//check if event is one we care about
// for now, just anything associated with new processes/exits
-(BOOL)shouldProcessRecord:(u_int16_t)eventType
{
    //flag
    BOOL shouldProcess =  NO;
    
    //check
    if( (eventType == AUE_EXEC) ||
        (eventType == AUE_EXIT) ||
        (eventType == AUE_FORK) ||
        (eventType == AUE_EXECVE) ||
        (eventType == AUE_POSIX_SPAWN) )
    {
        //set flag
        shouldProcess = YES;
    }
    
    return shouldProcess;
}

//register for app launchings
-(void)appMonitor
{
    //notification center
    NSNotificationCenter* center = nil;
    
    //get shared center
    center = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    //register app start notification
    [center addObserver:self selector:@selector(appEvent:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    
    //register app exit notifcation
    [center addObserver:self selector:@selector(appEvent:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    
    return;
}

//automatically invoked when an app is started/exits
// create new process object and add to dictionary
-(void)appEvent:(NSNotification *)notification
{
    //process object
    Process* process = nil;
    
    //pid
    pid_t processID = -1;
    
    //get process id
    processID = [notification.userInfo[@"NSApplicationProcessIdentifier"] intValue];
    
    //app start?
    if(YES == [notification.name isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"])
    {
        //create a new process obj
        process = [[Process alloc] init:processID];
        if(nil == process)
        {
            #ifdef DEBUG
            
            //err msg
            NSLog(@"ERROR: failed to create process object for %d/%@", processID, notification.userInfo);
            
            #endif
            
            //bail
            goto bail;
        }
        
        //start event
        [self handleProcessStart:process];
    }
    
    //app exit
    else
    {
        //alloc new process obj
        process = [[Process alloc] init];
        
        //manually set pid
        process.pid = processID;
        
        //manully set type to exit
        process.type = EVENT_EXIT;
        
        //exit event
        [self handleProcessExit:process];
    }
    
bail:
    
    return;
}

//handle new process
// create Binary obj/enum/process ancestors, etc
-(void)handleProcessStart:(Process*)process
{
    //default cs flags
    // note: since this is dynamic check, we don't need to check all architectures, or skip resources, etc...
    SecCSFlags flags = kSecCSDefaultFlags;
    
    //sanity check
    // should only occur for fork() events, which normally get superceeded by an exec(), etc
    if( (-1 == process.pid) ||
        (nil == process.path) )
    {
        //bail
        goto bail;
    }
    
    //get parent
    if(-1 == process.ppid)
    {
        //get ppid
        process.ppid = [Process getParentID:process.pid];
    }
    
    //enumerate process ancestry
    if(0 == process.ancestors.count)
    {
        //enumerate
        [process enumerateAncestors];
    }
    
    //generate binary
    process.binary = [[Binary alloc] init:process.path];
    if(nil == process.binary)
    {
        #ifdef DEBUG
        
        //err msg
        NSLog(@"ERROR: failed to create binary object for %d/%@", process.pid, process.path);
        
        #endif
        
        //bail
        goto bail;
    }
    
    //automatically generate signing info/icon?
    // these can be skipped for performance reasons
    if(YES != self.goEasy)
    {
        //generate signing info
        // first will try dynamic, falling back to static
        [process generateSigningInfo:flags];
    
        //set icon
        [process.binary getIcon];
    }
    
    //invoke user callback
    self.processCallback(process);

bail:
    
    return;
}

//handle process exit event
// as only have pid, just alert user
-(void)handleProcessExit:(Process*)process
{
    //invoke user callback
    self.processCallback(process);
    
    return;
}

//return array of running processes
-(NSMutableArray*)currentProcesses
{
    //default cs flags
    // note: since this is dynamic check, we don't need to check all architectures, or skip resources, etc...
    SecCSFlags flags = kSecCSDefaultFlags;
    
    //current process
    Process* currentProcess = nil;
    
    //processes
    NSMutableArray* processes = nil;
    
    //alloc array
    processes = [NSMutableArray array];
    
    //iterate over all pids
    // init process object w/ pid/path, etc
    for(NSNumber* pid in PI_enumerateProcesses())
    {
        //create process obj
        currentProcess = [[Process alloc] init:pid.intValue];
        if(nil == currentProcess)
        {
            //skip
            continue;
        }
        
        //generate signing info
        [currentProcess generateSigningInfo:flags];
        
        //add
        [processes addObject:currentProcess];
    }
    
    return processes;
}

@end
