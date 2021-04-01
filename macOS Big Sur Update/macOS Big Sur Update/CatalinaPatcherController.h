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

#import <Foundation/Foundation.h>
#import "PatchHandler.h"
#import "STPrivilegedTask.h"
#import "CatalinaPatcherLoggingManager.h"
#import "AnalyticsManager.h"
#import "APFSManager.h"

#define systemCompatibilityFile "macModels.plist"
#define kSystemNeedsAPFSROMUpdate "needsAPFSBootROMUpdate"

typedef enum {
    modeCreateInstallerVolume = 0,
    modeInstallToSameMachine = 1,
    modeCreateISO = 2
}mode;

typedef enum {
    compatibilityStateIsSupportedMachine = 0,
    compatibilityStateNeedsAPFSROMUpdate = 1,
    compatibilityStateIsUnsupportedMachine = 2,
    compatibilityStateIsNativelySupportedMachine = 3
}compatibilityState;

@protocol CatalinaPatcherControllerDelegate <NSObject>

-(void)updateProgressWithValue:(double)percent;
-(void)updateProgressStatus:(NSString *)status;
-(void)operationDidComplete;
-(void)operationDidFailWithError:(err)error;
-(void)setProgBarMaxValue:(double)maxValue;
-(void)helperFailedLaunchWithError:(OSStatus)err;
-(void)displayHelperError:(NSString *)message withInfo:(NSString *)info;

@end


@interface CatalinaPatcherController : NSObject <PatchHandlerDelegate>
{
    NSString *installerAppPath;
    NSString *installerVolumePath;
    PatchHandler *ph;
    BOOL shouldUseAPFSBooter;
    BOOL shouldAutoApplyPostInstall;
    NSString *isoPath;
    NSString *targetPatchedAppPath;
    NSString *installerAppVersion;
}
@property (strong) id <CatalinaPatcherControllerDelegate> delegate;
-(id)init;
+ (CatalinaPatcherController *)sharedInstance;
-(BOOL)setInstallerAppPath:(NSString *)appPath withVerification:(BOOL)verify;
-(void)setTargetVolume:(NSString *)volume;
-(int)startProcessInMode:(mode)desiredMode;
-(void)setISOPath:(NSString *)path;
-(void)setTargetPatchedAppPath:(NSString *)appPath;
-(compatibilityState)checkSystemCompatibility;

@end
