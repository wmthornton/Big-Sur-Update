/**

Created by: Wayne Michael Thornton on 4/1/21

Portions Copyright © 2020 to Present Wayne Michael Thornton aka Dexter's Laboratory. All Rights Reserved.

This file may be based on or incorporate material from other projects licensed under open-source licenses, collectively, “Third Party Code”).   Developer is not the original author of the Third Party Code.   The original copyright notice and license, under which developer received such Third Party Code, are set out within the “Third-Party Licenses Readme” included with this file.  Such licenses and notices are provided for informational purposes only.  Developer, not the third party, licenses the Third Party Code to you under the terms set forth in the license terms for the source product.  Developer reserves all other rights not expressly granted under this agreement, whether by implication, estoppel or otherwise.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#import <Cocoa/Cocoa.h>

//macOS 10.15
#define targetMinorVersion 15

typedef enum
{
    downloadError = 0,
    appError = 1,
    catalogError = 2,
    overwriteDecline = 3
}error;

typedef enum
{
    alertConfirmDownload=0
}downloadAlert;

@protocol DownloaderDelegate <NSObject>
@optional
-(void)updateProgressPercentage:(double)percent;
-(void)updateProgressSize:(NSString *)size;
-(void)updateProgressStatus:(NSString *)status;
-(void)setIndefiniteProgress:(BOOL)indefinite;
-(void)downloadDidFailWithError:(error)err;
-(void)shouldLoadApp:(BOOL)shouldLoad atPath:(NSString *)path;
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
    
    long dlSize;
    long dataLength;
    double percent;
    long totalDownloadSize;
    
    NSWindow *windowForAlertSheets;
}

@property (nonatomic, strong) id <DownloaderDelegate> delegate;
-(id)init;
-(void)startDownloadingToPath:(NSString *)path withWindowForAlertSheets:(NSWindow *)win;
-(void)cancelDownload;
@property (strong) NSURLConnection *urlConnection;

@end
