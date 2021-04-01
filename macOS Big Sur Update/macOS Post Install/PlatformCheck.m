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

#import "PlatformCheck.h"

@implementation PlatformCheck

-(id)init {
    self = [super init];
    [self setID:@"platformCheckPatch"];
    [self setVersion:2];
    [self setName:@"Platform Check Patch"];
    return self;
}
-(int)applyToVolume:(NSString *)volumePath {
    
    int ret = 0;
    
    [self setBootPlistAtPath:[volumePath stringByAppendingPathComponent:@"Library/Preferences/SystemConfiguration/com.apple.Boot.plist"]];
    [self setPlatformSupportPlistAtPath:[volumePath stringByAppendingPathComponent:@"System/Library/CoreServices/PlatformSupport.plist"]];
    
    NSString *prebootDisk = [[APFSManager sharedInstance] getPrebootVolumeforAPFSVolumeAtPath:volumePath];
    NSString *volumeUUID = [[APFSManager sharedInstance] getUUIDOfVolumeAtPath:volumePath];
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:@[@"mount", prebootDisk]];
    [mount launch];
    [mount waitUntilExit];
    
    [self setBootPlistAtPath:[NSString stringWithFormat:@"/Volumes/Preboot/%@/Library/Preferences/SystemConfiguration/com.apple.Boot.plist", volumeUUID]];
    [self setPlatformSupportPlistAtPath:[NSString stringWithFormat:@"/Volumes/Preboot/%@/System/Library/CoreServices/PlatformSupport.plist", volumeUUID]];
    
    NSTask *unmount = [[NSTask alloc] init];
    [unmount setLaunchPath:@"/usr/sbin/diskutil"];
    [unmount setArguments:@[@"unmount", prebootDisk]];
    [unmount launch];
    [unmount waitUntilExit];
    
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
