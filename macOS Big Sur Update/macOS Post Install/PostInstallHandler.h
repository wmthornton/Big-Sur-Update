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
#import "Patch.h"
#import "PlatformCheck.h"
#import "LegacyGPU.h"
#import "LegacyUSB.h"
#import "LegacyPlatform.h"
#import "SIPDisabler.h"
#import "LegacyWiFi.h"
#import "BCM94321Patch.h"
#import "LegacyEnet.h"
#import "LegacyAudio.h"
#import "LegacyIDE.h"
#import "InstallPatchUpdater.h"
#import "APFSPatch.h"
#import "VolumeControlPatch.h"
#import "AMDSSE4.h"
#import "LibraryValidation.h"
#import "RecoveryPartitionPatch.h"

@interface PostInstallHandler : NSObject
{
    NSArray *availablePatches;
    NSDictionary *availablePatchesDict;
    NSDictionary *macModels;
    NSString *resourcePath;
}

+ (PostInstallHandler *)sharedInstance;
-(id)init;
-(NSArray *)getAllPatches;
-(void)setPermissionsOnDirectory:(NSString *)path;
-(NSArray *)getOptimalPatchesForModel:(NSString *)macModel;
-(NSString *)getMachineModel;
-(BOOL)volumeContainsCatalina:(NSString *)volumePath;
-(NSArray *)getAvailableVolumes;
-(NSArray *)getAllModels;
-(NSString *)getCatalinaVolume;
-(void)rebootSystemWithCacheRebuild:(BOOL)rebuildCaches onVolume:(NSString *)volumePath;
-(void)beginForceCacheRebuildOnVolume:(NSString *)volumePath;
-(void)updateDyldSharedCacheOnVolume:(NSString *)volumePath;

@end
