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

#import "UpdateManager.h"

@interface UpdateManager ()

@end

@implementation UpdateManager

-(id)init
{
    self = [super initWithWindowNibName:@"UpdateManager"];
    allDownloadableUpdates = [[UpdateController sharedInstance] getAllUpdates];
    installedPatches = [[UpdateController sharedInstance] getInstalledPatches];
    [self initUpdates];
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self setUpView];
}
-(void)setUpView
{
    [self.installedPatchesTable setDelegate:self];
    [self.installedPatchesTable setDataSource:self];
    NSMenu *contextMenu = [[NSMenu alloc] init];
    [contextMenu setAutoenablesItems:NO];
    [contextMenu setDelegate:self];
    NSMenuItem *reInstall = [[NSMenuItem alloc] initWithTitle:@"Re-install..." action:@selector(reinstallSelectedPatchUpdates) keyEquivalent:@""];
    [reInstall setTarget:self];
    [contextMenu addItem:reInstall];
    [self.installedPatchesTable setMenu:contextMenu];
}
-(void)initUpdates
{
    updatesToShow = [[NSMutableArray alloc] init];
    for (Update *upd in allDownloadableUpdates)
    {
        if ([self isUpdateInstalled:upd])
        {
            [updatesToShow addObject:upd];
        }
    }
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return updatesToShow.count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:@"patchName"])
    {
        return [[updatesToShow objectAtIndex:row] getUserVisibleName];
    }
    else if ([[tableColumn identifier] isEqualToString:@"patchVersion"])
    {
        return [[installedPatches objectForKey:[[updatesToShow objectAtIndex:row] getName]] objectForKey:@"version"];
    }
    return nil;
}
-(BOOL)isUpdateInstalled:(Update *)update
{
    if ([installedPatches objectForKey:[update getName]] != nil)
    {
        return true;
    }
    return false;
}
-(void)reinstallSelectedPatchUpdates
{
    NSMutableArray *updatesToInstall = [[NSMutableArray alloc] init];
    NSIndexSet *selectedIndices = [self.installedPatchesTable selectedRowIndexes];
    if (selectedIndices.count > 1)
    {
        NSUInteger lastIndex=[selectedIndices firstIndex];
        for (int i=0; i<selectedIndices.count; i++)
        {
            [updatesToInstall addObject:[updatesToShow objectAtIndex:lastIndex]];
            lastIndex=[selectedIndices indexGreaterThanIndex:lastIndex];
        }
    }
    else
    {
        if ([self.installedPatchesTable clickedRow] >= 0)
        {
            [updatesToInstall addObject:[updatesToShow objectAtIndex:[self.installedPatchesTable clickedRow]]];
        }
        else if ([self.installedPatchesTable selectedRow] >= 0)
        {
            [updatesToInstall addObject:[updatesToShow objectAtIndex:[self.installedPatchesTable selectedRow]]];
        }
    }
    [self.window close];
    [self.delegate beginReInstallingUpdates:updatesToInstall];
}
-(void)menuNeedsUpdate:(NSMenu *)menu
{
    if ([self.installedPatchesTable clickedRow] >= 0)
    {
        [[self.installedPatchesTable.menu itemAtIndex:0] setEnabled:YES];
    }
    else
    {
        [[self.installedPatchesTable.menu itemAtIndex:0] setEnabled:NO];
    }
}
-(void)showWindow
{
    [self.installedPatchesTable reloadData];
    [self showWindow:self.window];
}

- (IBAction)reInstallAllPatches:(id)sender
{
    if (updatesToShow.count > 0)
    {
        NSArray *updatesToInstall = [NSArray arrayWithArray:updatesToShow];
        [self.window close];
        [self.delegate beginReInstallingUpdates:updatesToInstall];
    }
}
@end
