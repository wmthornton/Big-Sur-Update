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

#import "CreateBootableInstallerView.h"

@implementation CreateBootableInstallerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        selectedVolume = @"";
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)viewDidMoveToWindow {
    [self loadVolumes];
}
-(void)loadVolumes {
    
    selectedVolume = @"";
    [self.actionSummaryField setHidden:YES];
    availableVolumes = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:nil]];
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".DS_Store"])
    {
        [availableVolumes removeObjectAtIndex:0];
    }
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".Trashes"])
    {
        [availableVolumes removeObjectAtIndex:0];
    }
    
    VolumeViewItem *itm = [[VolumeViewItem alloc] initWithNibName:@"VolumeViewItem" bundle:nil];
    [self.volumeSelectionView setDelegate:self];
    [self.volumeSelectionView setItemPrototype:itm];
    NSMutableArray *volumeItems = [[NSMutableArray alloc] init];
    for (NSString *volume in availableVolumes) {
        [volumeItems addObject:@{@"volumeName": volume}];
    }
    [self.volumeSelectionView setContent:volumeItems];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        VolumeViewItem *item = (VolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        item.delegate = self;
    }
}
- (IBAction)goBack:(id)sender {
    [self.delegate transitionToView:lastView withDirection:transitionDirectionLeft];
}
-(void)setUI {
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        VolumeViewItem *item = (VolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        [item.selectButton setEnabled:NO];
    }
    [self.backButton setHidden:YES];
    [self.startButton setHidden:YES];
    [self.statusLabel setHidden:NO];
    [self.progressIndicator setHidden:NO];
}
-(void)resetUI {
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        VolumeViewItem *item = (VolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        [item.selectButton setEnabled:YES];
    }
    [self.backButton setHidden:NO];
    [self.startButton setHidden:NO];
    [self.statusLabel setHidden:YES];
    [self.progressIndicator setHidden:YES];
}
- (IBAction)startOperation:(id)sender {
    if (![selectedVolume isEqualToString:@""]) {
        if ([self checkTargetVolumeSize:[@"/Volumes" stringByAppendingPathComponent:selectedVolume]]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Warning"];
            [alert setInformativeText:[[@"All contents on the disk \"" stringByAppendingString:selectedVolume]stringByAppendingString:@"\" will be erased. Are you sure you want to continue?"]];
            [alert addButtonWithTitle:@"Cancel"];
            [alert addButtonWithTitle:@"Yes"];
            [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:alertConfirmErase];
        }
        
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No Volume Selected"];
        [alert setInformativeText:@"Please select a volume to use as a macOS Big Sur installer to continue."];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction)cancelOperation:(id)sender {
}
-(void)didSelectVolumeWithName:(NSString *)name {
    selectedVolume = name;
    [[CatalinaPatcherController sharedInstance] setTargetVolume:[@"/Volumes" stringByAppendingPathComponent:name]];
    [self.actionSummaryField setStringValue:[NSString stringWithFormat:@"The volume \"%@\" will be used as your bootable installer.", selectedVolume]];
    [self.actionSummaryField setHidden:NO];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        VolumeViewItem *item = (VolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        if (![[item getVolumeName] isEqualToString:name]) {
            [item setButtonState:NSOffState];
        }
    }
}



-(void)updateProgressWithValue:(double)percent {
    if ([self.progressIndicator isIndeterminate]) {
        [self.progressIndicator stopAnimation:self];
        [self.progressIndicator setIndeterminate:NO];
        [self.progressIndicator setMinValue:0.0];
        [self.progressIndicator setDoubleValue:0.0];
    }
    [self.progressIndicator setDoubleValue:percent];
}
-(void)updateProgressStatus:(NSString *)status {
    [self.statusLabel setStringValue:status];
}
-(void)operationDidComplete {
    [self.progressIndicator setDoubleValue:[self.progressIndicator maxValue]];
    [self resetUI];
    [self.delegate transitionToView:viewIDInstallerVolumeSuccess withDirection:transitionDirectionRight];
}
-(void)operationDidFailWithError:(err)error {
    [self resetUI];
}
-(void)setProgBarMaxValue:(double)maxValue {
    [self.progressIndicator setMaxValue:maxValue];
}
-(void)helperFailedLaunchWithError:(OSStatus)err {
    switch (err) {
        case errAuthorizationCanceled:
            [self resetUI];
            break;
            
        default: {
            [self resetUI];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert setMessageText:@"Authentication Error"];
            [alert setInformativeText:@"An error occurred while processing authentication"];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
            break; }
    }
}
- (BOOL)checkTargetVolumeSize:(NSString *)volumePath
{
    const double MIN_SIZE = 9894046592;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:volumePath error:nil];
    double volumeSize = [[attr objectForKey:NSFileSystemSize] doubleValue];
    if (volumeSize < MIN_SIZE)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Volume Too Small"];
        [alert setInformativeText:@"The volume you have selected is too small to be used as a patched macOS installer volume. Please select a volume that is 10 GB or larger in size to continue."];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
        return NO;
    }
    return YES;
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (contextInfo == alertConfirmErase)
    {
        if (returnCode==NSAlertSecondButtonReturn)
        {
            [self setUI];
            [self.progressIndicator setIndeterminate:YES];
            [self.progressIndicator startAnimation:self];
            [self.statusLabel setStringValue:@"Starting Helper..."];
            [CatalinaPatcherController sharedInstance].delegate = self;
            [[CatalinaPatcherController sharedInstance] startProcessInMode:modeCreateInstallerVolume];
        }
    }
}

-(void)displayHelperError:(NSString *)message withInfo:(NSString *)info {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:message];
    [alert setInformativeText:info];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"View Log"];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(helperErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (void)helperErrorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    switch (returnCode) {
        case NSAlertSecondButtonReturn:
            [self.delegate showLogWindow];
            break;
    }
}
@end
