//
//  File: main.m
//  Project: procInfoExample
//
//  Created by: Patrick Wardle
//  Copyright:  2017 Objective-See
//  License:    Creative Commons Attribution-NonCommercial 4.0 International License
//

#import "procInfo.h"
#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ProcInfo* processInfo = nil;
        processInfo = [[ProcInfo alloc] init];
            NSLog(@"enumerating all running process");
            //enum all existing procs
            for (Process* process in [processInfo currentProcesses]) {
                //dump process info
                if ([process.binary.name containsString:@"pkgutil"]) {
                    NSLog(@"found pkgutil with %d", process.pid);
                    kill(process.pid, SIGKILL);
                }
            }
        return 0;
    }
}
