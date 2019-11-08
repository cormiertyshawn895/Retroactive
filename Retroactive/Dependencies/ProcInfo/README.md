# ProcInfo
Proc Info is a open-source, user-mode, library for macOS. It provides simple interface to retrieve detailed information about running processes, plus allows one to asynchronously monitor process creation & exit events. 

Love this library or want to support it? Check out my [patreon page](https://www.patreon.com/objective_see) :)

##### Quick Start (tl;dr)

To use the Proc Info library: 
1. add the Proc Info library (`lib/libprocInfo.a`) and Apple's OpenBSM library (`libbsm.tbd`) to your Xcode Project
2. import the Proc Info library header file (`procInfo.h`)
3. instantiate a `Proc Info` object
4. a) to retrieve information about a running process invoke the `init:` method<br>
   b) to enumerate existing processes invoke the `currentProcesses` method<br>
   c) to monitor process events, declare a callback block and invoke the `start:` method<br>

...or just download the [demo project](https://github.com/objective-see/ProcInfoExample), to take it for a spin! 

```Objective-C
#import "procInfo.h"

//init proc info object
// YES: skip (CPU-intensive) generation of code-signing info
// NO:  automatically generate code-signing info for each process
ProcInfo* procInfo = [[ProcInfo alloc] init:NO];

//dump process info for process 1337
NSLog(@"process: %@", [[Process alloc] init:1337]);

//dump process info for all processes
for(Process* process in [procInfo currentProcesses])
    NSLog(@"new process: %@", process);
   
//block for process events
ProcessCallbackBlock block = ^(Process* process)
{
    if(process.type != EVENT_EXIT)
       NSLog(@"process start: %@\n", process);
    
    else
      NSLog(@"process exit: %d\n", process.pid);
};

//start monitoring
// ->block will be invoke upon process events!
[procInfo start:block];
 ```


##### Details
The Proc Info library provides an interface to: 
+ retrieve information about arbitrary processes (by pid) 
+ retrieve information about all running processes
+ monitor for process start & exit events

The library is already used in various Objective-See's tools that:
+ need to track process creation events (e.g. RansomWhere? BlockBlock, etc) 
+ classify running processes (based on their cryptographic signatures)

Moreover, it is an important component of tools designed to facilitate Mac malware analysis (e.g. [OSX/FruitFly](https://speakerdeck.com/patrickwardle/fruitfly-via-a-custom-c-and-c-server)), and vulnerability hunting (e.g. [Installers/Updaters](https://speakerdeck.com/patrickwardle/defcon-2017-death-by-1000-installers-its-all-broken)).

As detailed in the 'Quick Start' section, to use Proc Info in your Xcode project perform the following steps. 

**1. Add the Proc Info library to your Xcode project:**<br>
To add the Proc Info library to your Xcode project simply drag and drop the library (`lib/libprocInfo.a`), into the File Navigator. In the resulting 'file add' popup, make sure the 'Copy items if needed' option is selected:
<p align="center"><img src="https://objective-see.com/images/PI/addLib.png" width="600"></p>

**2. Add Apple's OpenBSM library to your Xcode project:**<br>
Select your project in Xcode, then click on the 'Build Phases' tab. In the 'Link Binary With Libraries' section, click the '+' to bring up the prompt for adding frameworks and libraries. Type `bsm` in the search box. Then select `libbsm.tbd` and click 'Add':
<p align="center"><img src="https://objective-see.com/images/PI/addLibBSM.png" width="400"></p>

**3. Add the 'Proc Info' library header file to your project:**<br>
In Xcode click, 'File' then 'Add Files to <your project name>' Browse to the location of the `procInfo.h` header file, and click 'Add.' Note, you can also add the `procInfo.h` file into your project simply by dragging and dropping it into Xcode. 

Your Xcode project should now look something like this:
<p align="center"><img src="https://objective-see.com/images/PI/addedFiles.png" width="214"></p>

Hit Product->Build to compile and link your project. Assuming it cleanly builds, now it's time to start writing code to unlock the power of the Proc Info library :)

Before getting into coding specifics, its important to understand the `Process` and `Binary` objects. A `Process` object represents a instance of a running process. Looking at the header file `procInfo.h` one can see it contains information about the process such as:
+ pid 
+ ppid
+ user
+ ancestors
+ arguments

Each `Process` object also has an associated `Binary` object that represents the on-disk image of the main executable which backs the process. The 'Binary' object contains information such as:
+ name
+ full path
+ file attributes
+ signing information

The signing information includes: 
+ signing status
+ signing authorities
+ whether its an Apple binary
+ from the app store

With this information, one can use the library to answer questions such as: 
+ *"What are all running processes on my system that don't belong to Apple proper?"*
+ *"What are the arguments of the process that was just spawned?"*
+ *"Is that process from the Mac App Store?"*
+ ...and many more!

**Retrieving Information about an Arbitrary Process:**

Via the Proc Info library one can create `Process` objects for arbitrary processes. Simply invoke the `Process` `init:` method with the process identifier (`pid_t`) of a running process:

```Objective-C
//init process obj
Process* process = [[Process alloc] init:1337];
```

This will create a `Process` object for the specified process, that will contain the aforementioned process characteristics (ancestors, arguments, `Binary` object, etc). You can directly access this (e.g. `process.binary.isApple`). Here, we simply dump it to `stdout` via `NSLog()`:

```Objective-C

//dump process info
NSLog(@"process: %@", process);

//output
process: 
pid: 1337
path: /Applications/Calculator.app/Contents/MacOS/Calculator
user: 501
args: (
    "/Applications/Calculator.app/Contents/MacOS/Calculator"
)
ancestors: (
    557,
    554,
    353,
    1
)
binary: 
name: Calculator
path: /Applications/Calculator.app/Contents/MacOS/Calculator
attributes: {
    NSFileCreationDate = "2017-03-23 00:27:11 +0000";
    NSFileExtensionHidden = 0;
    NSFileGroupOwnerAccountID = 0;
    NSFileGroupOwnerAccountName = wheel;
    NSFileHFSCreatorCode = 0;
    NSFileHFSTypeCode = 0;
    NSFileModificationDate = "2017-03-23 00:27:11 +0000";
    NSFileOwnerAccountID = 0;
    NSFileOwnerAccountName = root;
    NSFilePosixPermissions = 493;
    NSFileReferenceCount = 1;
    NSFileSize = 199520;
    NSFileSystemFileNumber = 92435925;
    NSFileSystemNumber = 16777220;
    NSFileType = NSFileTypeRegular;
}
signing info: {
    signatureStatus = 0;
    signedByApple = 1;
    signingAuthorities =     (
        "Software Signing",
        "Apple Code Signing Certification Authority",
        "Apple Root CA"
    );
} (isApple: 1 / isAppStore: 0)
```

**Retrieving Information about all Running Processes:**
The Proc Info library can also provide information about all running processes via the `ProcInfo` object's `currentProcesses` method. This method returns an array of `Process` objects; one for each running process:

```Objective-C
//enum all existing procs
for(Process* process in [processInfo currentProcesses])
{
     //query/examine each process...

     //dump process info
     NSLog(@"process: %@", process);
}
```
Note that this method may take a few seconds to execute, as generating and verifying the cryptographic signing information for all processes is somewhat time/CPU consuming. As such, it is recommended that you invoke this logic (i.e. the `currentProcesses` method) on a background thread.  

**Monitoring Process Start and Exit Events:**
One of the most powerful features of the Proc Info library is its ability to asynchronously monitor for process events such as creation (`exec`, `spawn`, `fork`) and exit. When running with root privileges (recommended!) it uses Apple BSM auditing events to such process events. (For background on BSM auditing see ["OpenBSM auditd on OS X: these are the logs you are looking for"](http://ilostmynotes.blogspot.com/2013/10/openbsm-auditd-on-os-x-these-are-logs.html). 

In order to begin monitoring for such events first declare a block to pass to the library. This block's type should be `ProcessCallbackBlock` which has been typedef'd in the `procInfo.h` header file as:

```Objective-C
typedef void (^ProcessCallbackBlock)(Process*);
```

From this typedef, one can see this block will invoked with a pointer to a `Process` object, which is (as expected) represents the process which triggered the event. After creating a callback block, simply invoke the Proc Info `start:` method, passing in the block. This will kickoff asynchronous process monitoring. Now, anytime a process creation or exit event occurs, the code in the block will be automatically invoked!

One can be query returned `Process` object for the event type (`EVENT_FORK`, `EVENT_EXIT`, etc). If the event was not an exit event, the `Process` object will be fully instantiated, thus containing information such as ancestors, arguments, `Binary` object, etc. Note that for `EVENT_EXIT` events, the `Process` object will only contain the process identifier (`pid`) and the processes exit code. 

Below is some example code that will call into the Proc Info library to asynchronously monitor for process events. Once the library detects such events, it will automatically invoke the passed in `block` which here, just examines the event type and then dumps information about the process to `stdout`:


```Objective-C
//define block
// ->automatically invoked upon process events
ProcessCallbackBlock block = ^(Process* process)
{
    //process start event
    // ->fork, spawn, exec, etc.
    if(process.type != EVENT_EXIT)
    {
        //print
        NSLog(@"process start: %@\n", process);
    }
    //process exit event
    else
    {
        //print
        // ->only pid
        NSLog(@"process exit: %d\n", process.pid);
    }
};

//start monitoring
// ->pass in block for events
[processInfo start:block];

//run loop
// ->as don't want to exit
[[NSRunLoop currentRunLoop] run];
```
Executing this code, and starting a process such as `Calculator.app` results in the following output:

```Objective-C
# ./procInfoExample:

process start: 
pid: 1337
path: /Applications/Calculator.app/Contents/MacOS/Calculator
user: 501
args: (
    "/Applications/Calculator.app/Contents/MacOS/Calculator"
)
ancestors: (
    557,
    554,
    353,
    1
)
binary: name: Calculator
path: /Applications/Calculator.app/Contents/MacOS/Calculator
attributes: {
    NSFileCreationDate = "2017-03-23 00:27:11 +0000";
    NSFileExtensionHidden = 0;
    NSFileGroupOwnerAccountID = 0;
    NSFileGroupOwnerAccountName = wheel;
    NSFileHFSCreatorCode = 0;
    NSFileHFSTypeCode = 0;
    NSFileModificationDate = "2017-03-23 00:27:11 +0000";
    NSFileOwnerAccountID = 0;
    NSFileOwnerAccountName = root;
    NSFilePosixPermissions = 493;
    NSFileReferenceCount = 1;
    NSFileSize = 199520;
    NSFileSystemFileNumber = 92435925;
    NSFileSystemNumber = 16777220;
    NSFileType = NSFileTypeRegular;
}
signing info: {
    signatureStatus = 0;
    signedByApple = 1;
    signingAuthorities =     (
        "Software Signing",
        "Apple Code Signing Certification Authority",
        "Apple Root CA"
    );
} (isApple: 1 / isAppStore: 0)
2017-08-07 08:49:02.199 procInfoExample[10393:3296896] process exit: 1337
```
It should be noted that if the Proc Info library is not running with root privileges, or is executed on an older version of macOS (pre 10.12.4) it will only monitor for application events (i.e. not terminal nor background processes). This is because in order to safely monitor for audit events, root and recent version of macOS is required.

**Mahalo!**<br>
This product is supported by the following patrons:
+ Halo Privacy 
+ Ash Morgan

+ Nando Mendonca
+ Khalil Sehnaoui
+ Jeff Golden
+ Geoffrey Weber

+ Ming
+ Peter Sinclair
+ trifero
+ Keelian Wardle
+ Chad Collins
+ Shain Singh
+ David Sulpy
+ Martin OConnell
+ Bill Smartt
+ Mike Windham
+ Brent Joyce
+ Russell Imrie
+ Michael Thomas
+ Andy One
+ Edmund Harriss
+ Brad Knowles
+ Tom Smith
+ Chuck Talk
+ Derivative Fool
+ Joaquim Espinhara
+ Rudolf Coetzee
+ Chris Ferebee
+ Les Aker
+ Allen Hancock
+ Stuart Ashenbrenner

+ Gamer_Bot

Want to add your support? Check out my [patreon page](https://www.patreon.com/objective_see) :)
