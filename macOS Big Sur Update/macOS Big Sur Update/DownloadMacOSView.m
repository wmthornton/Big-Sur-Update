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

#import "DownloadMacOSView.h"

@implementation DownloadMacOSView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        downloader = [[MacOSDownloader alloc] init];
        downloader.delegate = self;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)goBack:(id)sender {
    [self.delegate transitionToView:lastView withDirection:transitionDirectionLeft];
}
-(void)setUI {
    [self.startButton setHidden:YES];
    [self.backButton setHidden:YES];
    [self.downloadStatusLabel setHidden:NO];
    [self.progressIndicator setHidden:NO];
    [self.progressIndicator startAnimation:self];
    [self.cancelButton setHidden:NO];
}
-(void)resetUI {
    [self.startButton setHidden:NO];
    [self.backButton setHidden:NO];
    [self.downloadStatusLabel setHidden:YES];
    [self.sizeLabel setHidden:YES];
    [self.progressIndicator setHidden:YES];
    [self.progressIndicator stopAnimation:self];
    [self.cancelButton setHidden:YES];
}
- (IBAction)startDownloading:(id)sender {
    [self setUI];
    [self.progressIndicator setIndeterminate:YES];
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator setMaxValue:100.0];
    [self.progressIndicator setMinValue:0.0];
    [self.progressIndicator setDoubleValue:0.0];
    downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:downloadPath error:nil];
    if ( [[attr valueForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink] )
        downloadPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:downloadPath error:nil];
    [downloader startDownloadingToPath:downloadPath withWindowForAlertSheets:self.window];
}
- (IBAction)cancelDownload:(id)sender {
    [self resetUI];
    [downloader cancelDownload];
}

-(void)updateProgressPercentage:(double)percent {
    [self.progressIndicator setDoubleValue:percent];
}
-(void)updateProgressSize:(NSString *)size {
    [self.sizeLabel setStringValue:size];
}
-(void)updateProgressStatus:(NSString *)status {
    [self.downloadStatusLabel setStringValue:status];
}
-(void)setIndefiniteProgress:(BOOL)indefinite {
    if (indefinite) {
        [self.sizeLabel setHidden:YES];
        [self.progressIndicator setIndeterminate:YES];
        [self.progressIndicator startAnimation:self];
    }
    else {
        [self.sizeLabel setHidden:NO];
        [self.progressIndicator setIndeterminate:NO];
        //[self.progressIndicator startAnimation:self];
    }
}
-(void)downloadDidFailWithError:(error)err {
    [self resetUI];
}
-(void)shouldLoadApp:(BOOL)shouldLoad atPath:(NSString *)path {
    /*[self.sizeLabel setHidden:YES];
    [self.progressIndicator setIndeterminate:NO];
    [self.progressIndicator setDoubleValue:[self.progressIndicator maxValue]];
    [self.startButton setHidden:NO];
    [self.backButton setHidden:NO];
    [self.cancelButton setHidden:YES];
    [self.downloadStatusLabel setStringValue:@"Complete!"];*/
    [self resetUI];
    if ([[CatalinaPatcherController sharedInstance] setInstallerAppPath:path withVerification:YES]) {
        [self.delegate transitionToView:viewIDPatchOptions withDirection:transitionDirectionRight];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"App Verification Failed"];
        [alert setInformativeText:@"The downloaded Catalina installer app did not contain the necessary files needed for this tool. Please delete the copy of macOS that was downloaded, and try downloading a new copy."];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
}
@end
