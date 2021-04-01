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

#import "ContributorsView.h"

@implementation ContributorsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        resourcePath = [[NSBundle mainBundle] resourcePath];
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)viewDidMoveToWindow{
    [self.contributorsTextView readRTFDFromFile:[resourcePath stringByAppendingPathComponent:@"Licenses.rtf"]];
    [self.contributorsTextView setTextColor:NSColor.textColor];
}
- (IBAction)goBack:(id)sender {
    [self.delegate transitionToView:lastView withDirection:transitionDirectionLeft];
}

- (IBAction)goToNext:(id)sender {
    compatibilityState s = [[CatalinaPatcherController sharedInstance] checkSystemCompatibility];
    switch (s) {
        case compatibilityStateNeedsAPFSROMUpdate:
            [self.delegate transitionToView:viewIDFirmwareUpdateNeeded withDirection:transitionDirectionRight];
            break;
        case compatibilityStateIsSupportedMachine:
            [self.delegate transitionToView:viewIDInstallerAppOptions withDirection:transitionDirectionRight];
            break;
        case compatibilityStateIsNativelySupportedMachine: {
            /*NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Natively Supported Machine"];
            [alert setInformativeText:@"This machine supports Catalina natively; you do not need to use this patch. You can still use it to create a patched Catalina installer to be used on another machine."];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];*/
            [self.delegate transitionToView:viewIDInstallerAppOptions withDirection:transitionDirectionRight];
            break;
        }
        case compatibilityStateIsUnsupportedMachine: {
            /*NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Unsupported Machine"];
            [alert setInformativeText:@"This machine is not compatible with Catalina using this patch. You can still create a patched installer drive, but it will not be bootable on this machine."];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];*/
            [self.delegate transitionToView:viewIDInstallerAppOptions withDirection:transitionDirectionRight];
            break;
        }
    }
}
@end
