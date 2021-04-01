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

#import "WizardWindowController.h"

@interface WizardWindowController ()

@end

@implementation WizardWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        currentViewIndex = 0;
        resourcePath = [[NSBundle mainBundle] resourcePath];
        shouldVerifyApp = YES;
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.mainView.delegate = self;
    self.contributorsView.delegate = self;
    self.installerOptionsView.delegate = self;
    self.downloadMacOSView.delegate = self;
    self.patchOptionsView.delegate = self;
    self.createBootableInstallerView.delegate = self;
    self.installerVolumeSuccessView.delegate = self;
    self.createISOView.delegate = self;
    self.isoCreationSuccessView.delegate = self;
    self.inPlacePreparationView.delegate = self;
    self.inPlacePreparationSuccessView.delegate = self;
    self.firmwareUpdateNeededView.delegate = self;
    currentView = viewIDMain;
    [self.window.contentView addSubview:self.mainView];
    [self.window.contentView setWantsLayer:YES];
    
}
-(void)transitionToDirection:(transitionDirection)direction withView:(NSView *)view  {
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    if (direction == transitionDirectionLeft) {
        [transition setSubtype:kCATransitionFromLeft];
    }
    else {
        [transition setSubtype:kCATransitionFromRight];
    }
    
    [self.window.contentView setAnimations:@{@"subviews":transition}];
    [[self.window.contentView animator] replaceSubview:[[self.window.contentView subviews] objectAtIndex:0] with:view];
}



-(void)transitionToView:(viewID)view withDirection:(transitionDirection)dir {
    WizardView *desiredView;
    switch (view) {
        case viewIDMain:
            desiredView = self.mainView;
            break;
        case viewIDContrib:
            desiredView = self.contributorsView;
            break;
        case viewIDDownload:
            desiredView = self.downloadMacOSView;
            break;
        case viewIDInstallerAppOptions:
            desiredView = self.installerOptionsView;
            break;
        case viewIDPatchOptions:
            desiredView = self.patchOptionsView;
            break;
        case viewIDCreateBootableInstaller:
            desiredView = self.createBootableInstallerView;
            break;
        case viewIDInstallerVolumeSuccess:
            desiredView = self.installerVolumeSuccessView;
            break;
        case viewIDCreateISO:
            desiredView = self.createISOView;
            break;
        case viewIDISOCreationSuccess:
            desiredView = self.isoCreationSuccessView;
            break;
        case viewIDInPlaceInstallationPreparation:
            desiredView = self.inPlacePreparationView;
            break;
        case viewIDInPlaceInstallationPreparationSuccess:
            desiredView = self.inPlacePreparationSuccessView;
            break;
        case viewIDFirmwareUpdateNeeded:
            desiredView = self.firmwareUpdateNeededView;
            break;
        case viewIDNA:
            break;
    }
    if ([desiredView getLastView] == viewIDNA) {
        [desiredView setLastView:currentView];
    }
    [self transitionToDirection:dir withView:desiredView];
    currentView = view;
}

-(IBAction)toggleDisableAPFSBooterMenu:(id)sender {
    if([self.disableAPFSBooterMenu state] == NSOnState) {
        [self.disableAPFSBooterMenu setState:NSOffState];
        [[PatcherFlags sharedInstance] setShouldUseAPFSBooter:YES];
    }
    else {
        [self.disableAPFSBooterMenu setState:NSOnState];
        [[PatcherFlags sharedInstance] setShouldUseAPFSBooter:NO];
    }
}

- (IBAction)toggleAutoApplyPostInstallMenu:(id)sender {
    if ([self.autoApplyPostInstallMenu state] == NSOnState) {
        [self.autoApplyPostInstallMenu setState:NSOffState];
        [[PatcherFlags sharedInstance] setShouldAutoApplyPostInstall:NO];
    }
    else {
        [self.autoApplyPostInstallMenu setState:NSOnState];
        [[PatcherFlags sharedInstance] setShouldAutoApplyPostInstall:YES];
    }
}

- (IBAction)showLogWindow:(id)sender {
    [self showLogWindow];
}

-(void)showLogWindow {
    if (!logWindow) {
        logWindow = [[LoggingWindowController alloc] initWithWindowNibName:@"LoggingWindowController"];
    }
    [logWindow showWindow:self];
}
@end
