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
#import "PostInstallHandler.h"
#import "Patch.h"

typedef enum {
    alertConfirmApply = 0
}alert;

@interface MainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSArray *availableVolumes;
    NSString *resourcePath;
    NSArray *availablePatches;
    NSString *desiredVolume;
    NSString *desiredModel;
    NSTimer *progTimer;
    int remainingTimeToApply;
    int remainingTimeToReboot;
    BOOL isInstaller;
}
@property (strong) IBOutlet NSTableView *patchesTable;
@property (strong) IBOutlet NSTextField *statusLabel;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSButton *applyButton;
@property (strong) IBOutlet NSButton *skipButton;
@property (strong) IBOutlet NSTextField *summaryField;
@property (strong) IBOutlet NSPanel *changePatchSettingsView;
@property (strong) IBOutlet NSPopUpButton *modelList;
@property (strong) IBOutlet NSPopUpButton *volumeList;
@property (strong) IBOutlet NSButton *changeSettingsButton;
@property (strong) IBOutlet NSTextField *autoActionStatusLabel;
@property (strong) IBOutlet NSButton *restartButton;
@property (strong) IBOutlet NSButton *forceCacheRebuildButton;
@property (strong) IBOutlet NSProgressIndicator *rebuildingCachesIndicator;
@property (strong) IBOutlet NSTextField *rebuildingCachesLabel;

- (IBAction)applySelectedPatches:(id)sender;
- (IBAction)skipPostInstall:(id)sender;
- (IBAction)showChangeSettingsView:(id)sender;
- (IBAction)dismissSettingsView:(id)sender;
- (IBAction)setDesiredModel:(id)sender;
- (IBAction)setDesiredVolume:(id)sender;
- (IBAction)rebootSystem:(id)sender;
- (IBAction)selectedForceCacheRebuild:(id)sender;


@end
