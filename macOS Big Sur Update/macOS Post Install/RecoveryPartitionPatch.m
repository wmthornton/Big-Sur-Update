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

#import "RecoveryPartitionPatch.h"

@implementation RecoveryPartitionPatch

-(id)init {
    self = [super init];
    [self setID:@"recoveryPartitionPatch"];
    [self setVersion:1];
    [self setName:@"Recovery Partition Patch"];
    return self;
}
-(int)applyToVolume:(NSString *)volumePath {
    
    int ret = 0;
    BOOL isRecoveryOS = NO;
    NSString *recoveryVolumePath = @"/Volumes/Recovery";
    
    NSString *recoveryDisk = [[APFSManager sharedInstance] getRecoveryVolumeforAPFSVolumeAtPath:volumePath];
    NSString *volumeUUID = [[APFSManager sharedInstance] getUUIDOfVolumeAtPath:volumePath];
    
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:@[@"mount", recoveryDisk]];
    [mount launch];
    [mount waitUntilExit];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:recoveryVolumePath]) {
        isRecoveryOS = YES;
        mount = [[NSTask alloc] init];
        [mount setLaunchPath:@"/usr/sbin/diskutil"];
        [mount setArguments:@[@"mount", @"-uw", recoveryDisk]];
        [mount launch];
        [mount waitUntilExit];
        recoveryVolumePath = @"/Volumes/Image Volume";
    }
    
    [self setPlatformSupportPlistAtPath:[NSString stringWithFormat:@"%@/%@/PlatformSupport.plist", recoveryVolumePath, volumeUUID]];
    [self setBootPlistAtPath:[NSString stringWithFormat:@"%@/%@/com.apple.Boot.plist", recoveryVolumePath, volumeUUID]];
    ret = [self copyFile:[resourcePath stringByAppendingPathComponent:@"prelinkedkernel"] toDirectory:[NSString stringWithFormat:@"%@/%@", recoveryVolumePath, volumeUUID]];
    if (ret) {
        return ret;
    }
    ret = [self copyFile:[resourcePath stringByAppendingPathComponent:@"patchedfiles/boot.efi"] toDirectory:[NSString stringWithFormat:@"%@/%@", recoveryVolumePath, volumeUUID]];
    
    if (!isRecoveryOS) {
        NSTask *unmount = [[NSTask alloc] init];
        [unmount setLaunchPath:@"/usr/sbin/diskutil"];
        [unmount setArguments:@[@"unmount", recoveryDisk]];
        [unmount launch];
        [unmount waitUntilExit];
    }
    
    return ret;
}

-(BOOL)shouldInstallOnMachineModel:(NSString *)model {
    NSDictionary *machinePatches = [macModels objectForKey:model];
    if (machinePatches) {
        return YES;
    }
    return NO;
}

@end
