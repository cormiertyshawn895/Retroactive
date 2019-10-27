//
//  insert_dylib_tests.m
//  insert_dylib_tests
//
//  Created by Asger Hautop Drewsen on 16/06/15.
//  Copyright (c) 2015 Tyilo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#define TEST_TEXT @"insert_dylib_test"
#define XCRUN @"/usr/bin/xcrun"
#define SYSROOT_SUFFIX @"/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
#define TEST_DYLIB @"@executable_path/libfoo.dylib"
#define CODESIGN_ID @"task_for_pid"

NSString *insert_dylib_path;
NSString *test_source;

NSArray *x86_archs;
NSArray *arm_archs;

__attribute__((constructor)) void initialize_archs(void) {
	x86_archs = @[@"i386", @"x86_64"];
	arm_archs = @[@"armv7", @"arm64"];
}

NSArray *x86_binaries;
NSArray *arm_binaries;

@interface insert_dylib_tests : XCTestCase
@property NSArray *x86_binaries;
@property NSArray *arm_binaries;
@property BOOL successful;
@end

@implementation insert_dylib_tests

+ (NSString *)tmpfile {
	char *tmp = strdup("/tmp/insert_dylib_test.XXXXXX");
	NSString *file = [NSString stringWithUTF8String:mktemp(tmp)];
	free(tmp);
	return file;
}

+ (NSString *)getOutputFromPath:(NSString *)path arguments:(NSArray *)args status:(int *)status {
	NSTask *task = [NSTask new];
	task.launchPath = path;
	task.arguments = args;

	NSPipe *pipe = [NSPipe pipe];
	task.standardOutput = pipe;

	[task launch];
	[task waitUntilExit];

	int _status = [task terminationStatus];

	if(status) {
		*status = _status;
	} else {
		assert(_status == 0);
	}

	NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
	NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *)iOSSysrootDirectory {
	static NSString *dir = nil;
	if(!dir) {
		dir = [[self getOutputFromPath:XCRUN arguments:@[@"xcode-select", @"-p"] status:NULL] stringByAppendingString:SYSROOT_SUFFIX];
	}
	return dir;
}

+ (NSString *)generateBinaryWithArchitectures:(NSArray *)archs foriOS:(BOOL)iOS {
	NSMutableArray *args = [NSMutableArray new];
	[args addObject:@"clang"];
	[args addObject:@"-x"];
	[args addObject:@"c"];

	for(NSString *arch in archs) {
		[args addObject:@"-arch"];
		[args addObject:arch];
	}

	if(iOS) {
		[args addObject:@"-miphoneos-version-min=1.0"];
		[args addObject:@"-isysroot"];
		[args addObject:[self iOSSysrootDirectory]];
	}

	NSString *binary = [self tmpfile];

	[args addObject:@"-o"];
	[args addObject:binary];

	[args addObject:test_source];

	[self getOutputFromPath:XCRUN arguments:args status:NULL];

	return binary;
}

+ (NSArray *)generateBinariesForArchs:(NSArray *)archs iOS:(BOOL)iOS {
	NSMutableArray *arr = [NSMutableArray new];
	for(NSString *arch in archs) {
		[arr addObject:[self generateBinaryWithArchitectures:@[arch] foriOS:iOS]];
	}
	[arr addObject:[self generateBinaryWithArchitectures:archs foriOS:iOS]];
	return arr;
}

+ (void)setUp {
	[super setUp];

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	insert_dylib_path = [[[bundle bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"insert_dylib"];
	test_source = [bundle pathForResource:@"test.c" ofType:@"foo"];

	x86_binaries = [self generateBinariesForArchs:x86_archs iOS:NO];
	arm_binaries = [self generateBinariesForArchs:arm_archs iOS:YES];
}

+ (void)tearDown {
	for(NSString *binary in [x86_binaries arrayByAddingObjectsFromArray:arm_binaries]) {
		[[NSFileManager defaultManager] removeItemAtPath:binary error:NULL];
	}
}

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected {
	[super recordFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
	self.successful = NO;
}

- (NSArray *)copyBinaries:(NSArray *)binaries {
	NSMutableArray *arr = [NSMutableArray new];
	for(NSString *binary in binaries) {
		NSString *tmp = [[self class] tmpfile];
		[[NSFileManager defaultManager] copyItemAtPath:binary toPath:tmp error:NULL];
		[arr addObject:tmp];
	}
	return arr;
}

- (void)setUp {
    [super setUp];

	self.successful = YES;

	self.x86_binaries = [self copyBinaries:x86_binaries];
	self.arm_binaries = [self copyBinaries:arm_binaries];
}

- (void)tearDown {
	if(self.successful) {
		for(NSString *binary in [self.x86_binaries arrayByAddingObjectsFromArray:self.arm_binaries]) {
			[[NSFileManager defaultManager] removeItemAtPath:binary error:NULL];
		}
	}

    [super tearDown];
}

- (NSString *)getOutputFromPath:(NSString *)path arguments:(NSArray *)args {
	int res;
	NSString *output = [[self class] getOutputFromPath:path arguments:args status:&res];
	XCTAssertEqual(res, 0, @"Failed to run %@ with arguments: %@", path, args);
	return output;

}

- (void)insertDylib:(NSArray *)args {
	[self getOutputFromPath:insert_dylib_path arguments:args];
}

- (void)testBinary:(NSString *)path {
	XCTAssertEqualObjects([self getOutputFromPath:path arguments:@[]], TEST_TEXT, @"%@ outputted unexpected text", path);
}

- (void)codesign:(NSString *)path {
	[self getOutputFromPath:XCRUN arguments:@[@"codesign", @"-s", CODESIGN_ID, path]];
}

- (void)testRunAfterAddingWeakLibrary {
	for(NSString *binary in self.x86_binaries) {
		[self insertDylib:@[@"--all-yes", @"--inplace", @"--weak", TEST_DYLIB, binary]];
		[self testBinary:binary];
	}
}

- (void)testCodesign {
	for(NSString *binary in self.x86_binaries) {
		[self codesign:binary];
		[self testBinary:binary];

		[self insertDylib:@[@"--all-yes", @"--inplace", @"--weak", TEST_DYLIB, binary]];
		[self testBinary:binary];

		[self codesign:binary];
		[self testBinary:binary];
	}
	for(NSString *binary in self.arm_binaries) {
		[self codesign:binary];

		[self insertDylib:@[@"--all-yes", @"--inplace", @"--weak", TEST_DYLIB, binary]];

		[self codesign:binary];
	}
}

@end
