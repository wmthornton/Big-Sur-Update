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

#import "CreateISOView.h"

@implementation CreateISOView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)setUI {

    [self.backButton setHidden:YES];
    [self.startButton setHidden:YES];
    [self.statusLabel setHidden:NO];
    [self.progressIndicator setHidden:NO];
}
-(void)resetUI {

    [self.backButton setHidden:NO];
    [self.startButton setHidden:NO];
    [self.statusLabel setHidden:YES];
    [self.progressIndicator setHidden:YES];
}
- (IBAction)goBack:(id)sender {
    [self.delegate transitionToView:lastView withDirection:transitionDirectionLeft];
}

- (IBAction)startOperation:(id)sender {
    NSSavePanel *save = [[NSSavePanel alloc] init];
    [save setTitle:@"Save ISO Image"];
    [save setPrompt:@"Save"];
    [save setAllowedFileTypes:@[@"iso"]];
    [save setNameFieldStringValue:@"BigSurInstallerPatched"];
    [save beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSOKButton)
        {
            NSString *path = [[save URL] path];
            [[CatalinaPatcherController sharedInstance] setISOPath:path];
            [self setUI];
            [self.progressIndicator setIndeterminate:YES];
            [self.progressIndicator startAnimation:self];
            [self.statusLabel setStringValue:@"Starting Helper..."];
            [CatalinaPatcherController sharedInstance].delegate = self;
            [[CatalinaPatcherController sharedInstance] startProcessInMode:modeCreateISO];
        }
    }];
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
    [self.delegate transitionToView:viewIDISOCreationSuccess withDirection:transitionDirectionRight];
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
