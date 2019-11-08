//
//  File: Binary.m
//  Project: Proc Info
//
//  Created by: Patrick Wardle
//  Copyright:  2017 Objective-See
//  License:    Creative Commons Attribution-NonCommercial 4.0 International License
//

#import "Consts.h"
#import "Signing.h"
#import "procInfo.h"
#import "Utilities.h"

#import <CommonCrypto/CommonDigest.h>

@implementation Binary

@synthesize icon;
@synthesize name;
@synthesize path;
@synthesize bundle;
@synthesize metadata;
@synthesize attributes;

//init binary object
// note: CPU-intensive logic (code signing, etc) called manually
-(id)init:(NSString*)binaryPath
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //not a full path?
        if(YES != [binaryPath hasPrefix:@"/"])
        {
            //try find via 'which'
            self.path = PI_which(binaryPath);
            if(nil == self.path)
            {
                //stuck with short path
                self.path = binaryPath;
            }
        }
        //full path
        // use as is
        else
        {
            //save path
            self.path = binaryPath;
        }
        
        //try load app bundle
        // will be nil for non-apps
        [self getBundle];
        
        //get name
        [self getName];
        
        //get file attributes
        [self getAttributes];
        
        //get meta data (spotlight)
        [self getMetadata];
    }

    return self;
}

//try load app bundle
// will be nil for non-apps
-(void)getBundle
{
    //first try just with path
    self.bundle = [NSBundle bundleWithPath:path];
    
    //that failed?
    // try find it dynamically
    if(nil == self.bundle)
    {
        //find bundle
        self.bundle = PI_findAppBundle(path);
    }
    
    return;
}

//figure out binary's name
// either via app bundle, or from path
-(void)getName
{
    //first try get name from app bundle
    // specifically, via grab name from 'CFBundleName'
    if(nil != self.bundle)
    {
        //extract name
        self.name = [self.bundle infoDictionary][@"CFBundleName"];
    }
    
    //no app bundle || no 'CFBundleName'
    // just use last component from path
    if(nil == self.name)
    {
        //set name
        self.name = [self.path lastPathComponent];
    }
    
    return;
}

//get file attributes
-(void)getAttributes
{
    //grab (file) attributes
    self.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
    
    return;
}

//get (spotlight) meta data
-(void)getMetadata
{
    //md item ref
    MDItemRef mdItem = nil;
    
    //attributes names
    CFArrayRef attributeNames = nil;

    //create
    mdItem = MDItemCreate(kCFAllocatorDefault, (CFStringRef)self.path);
    if(nil == mdItem)
    {
        //bail
        goto bail;
    }
    
    //copy names
    attributeNames = MDItemCopyAttributeNames(mdItem);
    if(nil == attributeNames)
    {
        //bail
        goto bail;
    }
    
    //get metadata
    self.metadata = CFBridgingRelease(MDItemCopyAttributes(mdItem, attributeNames));
    
bail:
    
    //release names
    if(NULL != attributeNames)
    {
        //release
        CFRelease(attributeNames);
        
        //unset
        attributeNames = NULL;
        
    }
    
    //release md item
    if(NULL != mdItem)
    {
        //release
        CFRelease(mdItem);
        
        //unset
        mdItem = NULL;
    }

    return;
}

//get an icon for a process
// for apps, this will be app's icon, otherwise just a standard system one
-(void)getIcon
{
    //icon's file name
    NSString* iconFile = nil;
    
    //icon's path
    NSString* iconPath = nil;
    
    //icon's path extension
    NSString* iconExtension = nil;
    
    //skip 'short' paths
    // otherwise system logs an error
    if( (YES != [self.path hasPrefix:@"/"]) &&
        (nil == self.bundle) )
    {
        //bail
        goto bail;
    }
    
    //for app's
    // extract their icon
    if(nil != self.bundle)
    {
        //get file
        iconFile = self.bundle.infoDictionary[@"CFBundleIconFile"];
        
        //get path extension
        iconExtension = [iconFile pathExtension];
        
        //if its blank (i.e. not specified)
        // go with 'icns'
        if(YES == [iconExtension isEqualTo:@""])
        {
            //set type
            iconExtension = @"icns";
        }
        
        //set full path
        iconPath = [self.bundle pathForResource:[iconFile stringByDeletingPathExtension] ofType:iconExtension];
        
        //load it
        self.icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }
    
    //process is not an app or couldn't get icon
    // try to get it via shared workspace
    if( (nil == self.bundle) ||
        (nil == self.icon) )
    {
        //extract icon
        self.icon = [[NSWorkspace sharedWorkspace] iconForFile:self.path];
    }
    
    //make standard size...
    [self.icon setSize:NSMakeSize(128, 128)];
    
bail:
    
    return;
}

//statically, generate signing info
-(void)generateSigningInfo:(SecCSFlags)flags
{
    //extract signing info statically
    self.signingInfo = extractSigningInfo(0, self.path, flags);

    return;
}

//generate hash
-(void)generateHash
{
    //file's contents
    NSData* fileContents = nil;
    
    //hash digest
    uint8_t digestSHA256[CC_SHA256_DIGEST_LENGTH] = {0};
    
    //load file
    fileContents = [NSData dataWithContentsOfFile:self.path];
    if( (0 == fileContents.length) ||
        (NULL == fileContents.bytes) )
    {
        //bail
        goto bail;
    }
    
    //clear buffer
    bzero(digestSHA256, CC_SHA256_DIGEST_LENGTH);
    
    //sha it
    CC_SHA256(fileContents.bytes, (unsigned int)fileContents.length, digestSHA256);
    
    //now init
    self.sha256 = [NSMutableString string];
    
    //convert to NSString
    // iterate over each byte in computed digest and format
    for(NSUInteger index=0; index < CC_SHA256_DIGEST_LENGTH; index++)
    {
        //format/append
        [self.sha256 appendFormat:@"%02X", digestSHA256[index]];
    }
    
bail:

    return;
}

//generate id
// either signing id, or sha256 hash
// note: will generate signing info if needed
-(void)generateIdentifier
{
    //generate signing info?
    if(nil == self.signingInfo)
    {
        //generate
        [self generateSigningInfo:kSecCSDefaultFlags];
    }
    
    //validly signed binary?
    // use its signing identifier
    if( (noErr == [self.signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
        (0 != [self.signingInfo[KEY_SIGNATURE_AUTHORITIES] count]) &&
        (nil != self.signingInfo[KEY_SIGNATURE_IDENTIFIER]) )
    {
        //use signing id
        self.identifier = self.signingInfo[KEY_SIGNATURE_IDENTIFIER];
    }
    //not validly signed or unsigned
    // generate sha256 hash for identifier
    else
    {
        //generate hash?
        if(0 != self.sha256.length)
        {
            //hash
            [self generateHash];
        }
        
        //use hash
        self.identifier = self.sha256;
    }
    
    return;
}

//for pretty printing
-(NSString *)description
{
    //pretty print
    return [NSString stringWithFormat: @"name: %@\npath: %@\nattributes: %@\nsigning info: %@", self.name, self.path, self.attributes, self.signingInfo];
}

@end
