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

typedef enum {
    errMountingBSImage = 1,
    errMountingESDImage = 2,
    errCopyingSharedSupport = 3,
    errSavingBSImage = 4,
    errSavingESDImage = 5,
    errRestoringBSImage = 6,
    errBaseSystemPerms = 7,
    errPatchingBaseSystem = 8,
    errPatchingInstallESD = 9,
    isoErrCreatingBaseImage = 10,
    errCopyingBooterFiles = 11,
    errLaunchingInstaller = 12,
    errLoadingLibValKext = 13,
    errSettingLibValKextPerms = 14,
    errSIPEnabled = 15,
    errPreparingFSForInPlaceInstall = 16
}err;

@protocol LoggingDelegate <NSObject>

-(void)logDidUpdateWithText:(NSString *)text;

@end

@interface LoggingManager : NSObject


@property (strong) id <LoggingDelegate> delegate;
- (id)init;
+ (LoggingManager *)sharedInstance;
-(void)setOutputPipe:(NSPipe *)pipe;

@end
