//
//  MacOSDownloader.h
//  macOS High Sierra Patcher
//
//  Created by Collin Mistr on 8/21/17.
//  Copyright (c) 2017 dosdude1 Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    downloadError = 0,
    appError = 1,
    catalogError = 2,
    overwriteDecline = 3
} error;

typedef enum
{
    alertConfirmDownload=0
} downloadAlert;

typedef enum
{
    searchCatalog = 0,
    downloadInstaller = 1,
    extractInstaller = 2,
    verifyInstaller = 3
} stage;

@protocol DownloaderDelegate <NSObject>
@optional
- (void)updateProgressPercentage:(double)percent;
- (void)updateProgressSize:(NSString *)size;
- (void)updateProgressStatus:(NSString *)status;
- (void)updateProgressStage:(stage)stage;
- (void)setIndefiniteProgress:(BOOL)indefinite;
- (void)downloadDidFailWithError:(error)err;
- (void)shouldLoadApp:(BOOL)shouldLoad atPath:(NSString *)path;
@end

@interface MacOSDownloader : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSDictionary *downloadSettings;
    NSString *catalogURL;
    NSString *savePath;
    NSString *downloadingURL;
    NSString *downloadPath;
    NSMutableArray *filesToDownload;
    NSFileHandle *downloadingFile;
    NSString *metadataURL;
    
    int targetMinorVersion;
    
    long dlSize;
    long dataLength;
    double percent;
    long totalDownloadSize;
    
    NSWindow *windowForAlertSheets;
}

@property (nonatomic, strong) id <DownloaderDelegate> delegate;
@property (strong) NSURLConnection *urlConnection;

- (id)initWithCatalogURL:(NSString *)catalog metadataURL:(NSString *)metadata minorVersion:(int)minorVersion;
- (void)startDownloadingToPath:(NSString *)path withWindowForAlertSheets:(NSWindow *)win;
- (void)cancelDownload;

@end
