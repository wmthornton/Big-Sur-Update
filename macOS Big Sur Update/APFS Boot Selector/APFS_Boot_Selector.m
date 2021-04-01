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

#import "APFS_Boot_Selector.h"

@implementation APFS_Boot_Selector

- (void)mainViewDidLoad {
    [self initHelper];
}
-(void)didSelect {
    if ([[self.volumeSelectionView content] count] > 0) {
        for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
            APFSVolumeViewItem *item = (APFSVolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
            [item setTextHighlightColor:[[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]];
        }
    }
    [self loadVolumes];
}
-(void)initHelper {
    helper = (APFSPrefpaneHelper *)[NSConnection rootProxyForConnectionWithRegisteredName:@SERVER_ID host:nil];
    if (!helper) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"Error Communicating with Helper"];
        [alert setInformativeText:@"Could not communicate with helper process."];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:[[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        [self disableUI];
    }
    [helper setResourcesPath:[[NSBundle bundleForClass:[self class]] resourcePath]];
    helper.delegate = self;
}
-(void)disableUI {
    [self.restartButton setEnabled:NO];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        APFSVolumeViewItem *item = (APFSVolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        [item.selectButton setEnabled:NO];
        [item.selectButtonLabel setEnabled:NO];
    }
}
-(void)enableUI {
    [self.restartButton setEnabled:YES];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        APFSVolumeViewItem *item = (APFSVolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        [item.selectButton setEnabled:YES];
        [item.selectButtonLabel setEnabled:YES];
    }
}

- (IBAction)beginReboot:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Are you sure you want to restart the computer?"];
    [alert setInformativeText:[NSString stringWithFormat:@"Your computer will start up from the volume \"%@\".", selectedVolume]];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:[[self mainView] window] modalDelegate:self didEndSelector:@selector(rebootConfirmAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (void)rebootConfirmAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSAppleScript *reboot = [[NSAppleScript alloc] initWithSource:@"tell app \"System Events\" to restart"];
        [reboot executeAndReturnError:nil];
    }
}
-(void)setSelectedVolumeLabelWithVolumeName:(NSString *)volName {
    if ([volName isEqualToString:@""]) {
        [self.selectedVolumeLabel setStringValue:[NSString stringWithFormat:@"No APFS volume selected."]];
    } else {
        [self.selectedVolumeLabel setStringValue:[NSString stringWithFormat:@"You have selected \"%@\" as the Startup Volume.", volName]];
    }
}
-(void)didSelectVolumeWithName:(NSString *)name {
    selectedVolume = name;
    [self setSelectedVolumeLabelWithVolumeName:name];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        APFSVolumeViewItem *item = (APFSVolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        if (![[item getVolumeName] isEqualToString:name]) {
            [item setButtonState:NSOffState];
        }
    }
    
    [self disableUI];
    [self.statusLabel setStringValue:@"Setting Startup..."];
    [self.statusLabel setHidden:NO];
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator setHidden:NO];
    [helper performSelectorInBackground:@selector(beginSettingBootVolume:) withObject:selectedVolume];
}

-(void)loadVolumes {
    [self disableUI];
    [self.statusLabel setStringValue:@"Loading..."];
    [self.statusLabel setHidden:NO];
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator setHidden:NO];
    [helper performSelectorInBackground:@selector(beginLoadingAvailableVolumesForRoot) withObject:nil];
}
-(void)didSetStartupVolumeWithError:(err)errID {
    [self.statusLabel setHidden:YES];
    [self.progressIndicator stopAnimation:self];
    [self.progressIndicator setHidden:YES];
    [self enableUI];
}
-(void)didLoadVolumes:(NSArray *)volumes withCurrentBootVolume:(NSString *)currentVol withError:(err)errID {
    availableVolumes = volumes;
    selectedVolume = currentVol;
    APFSVolumeViewItem *itm = [[APFSVolumeViewItem alloc] initWithNibName:@"APFSVolumeViewItem" bundle:[NSBundle bundleForClass:[self class]]];
    [self.volumeSelectionView setDelegate:self];
    [self.volumeSelectionView setItemPrototype:itm];
    NSMutableArray *volumeItems = [[NSMutableArray alloc] init];
    for (NSString *volume in availableVolumes) {
        [volumeItems addObject:@{@"volumeName": volume}];
    }
    [self.volumeSelectionView setContent:volumeItems];
    for (NSUInteger itemIndex = 0; itemIndex < [[self.volumeSelectionView content] count]; itemIndex++) {
        APFSVolumeViewItem *item = (APFSVolumeViewItem *)[self.volumeSelectionView itemAtIndex:itemIndex];
        item.delegate = self;
        if ([[item getVolumeName] isEqualToString:currentVol]) {
            [item setButtonState:NSOnState];
            [self setSelectedVolumeLabelWithVolumeName:currentVol];
        }
    }
    [self.statusLabel setHidden:YES];
    [self.progressIndicator stopAnimation:self];
    [self.progressIndicator setHidden:YES];
    [self enableUI];
}
@end
