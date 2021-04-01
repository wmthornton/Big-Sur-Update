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

#import "PostInstallHandler.h"

@implementation PostInstallHandler

-(id)init {
    self = [super init];
    resourcePath = [[NSBundle mainBundle] resourcePath];
    [self loadAllPatches];
    [self loadMacModels];
    return self;
}
+ (PostInstallHandler *)sharedInstance {
    static PostInstallHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
-(void)loadAllPatches {
    
    NSMutableArray *patches = [[NSMutableArray alloc] init];
    [patches addObject:[[PlatformCheck alloc] init]];
    [patches addObject:[[InstallPatchUpdater alloc] init]];
    [patches addObject:[[LegacyGPU alloc] init]];
    [patches addObject:[[LegacyUSB alloc] init]];
    [patches addObject:[[LegacyPlatform alloc] init]];
    [patches addObject:[[APFSPatch alloc] init]];
    [patches addObject:[[SIPDisabler alloc] init]];
    [patches addObject:[[LegacyWiFi alloc] init]];
    [patches addObject:[[BCM94321Patch alloc] init]];
    [patches addObject:[[LegacyEnet alloc] init]];
    [patches addObject:[[LegacyAudio alloc] init]];
    [patches addObject:[[LegacyIDE alloc] init]];
    [patches addObject:[[VolumeControlPatch alloc] init]];
    [patches addObject:[[AMDSSE4 alloc] init]];
    [patches addObject:[[LibraryValidation alloc] init]];
    [patches addObject:[[RecoveryPartitionPatch alloc] init]];
    availablePatches = patches;
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    for (Patch *p in availablePatches) {
        [d setObject:p forKey:[p getID]];
    }
    availablePatchesDict = d;
}
-(void)loadMacModels {
    macModels = [[NSDictionary alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"macmodels.plist"]];
}
-(NSArray *)getAllPatches {
    return availablePatches;
}
-(void)setPermissionsOnDirectory:(NSString *)path {
    NSTask *chmod = [[NSTask alloc] init];
    [chmod setLaunchPath:@"/bin/chmod"];
    [chmod setArguments:@[@"-R", @"755", path]];
    [chmod launch];
    [chmod waitUntilExit];
    
    NSTask *chown = [[NSTask alloc] init];
    [chown setLaunchPath:@"/usr/sbin/chown"];
    [chown setArguments:@[@"-R", @"0:0", path]];
    [chown launch];
    [chown waitUntilExit];
}
-(NSArray *)getOptimalPatchesForModel:(NSString *)macModel {
    NSMutableArray *optimalPatches = [[NSMutableArray alloc] init];
    
    for (Patch *p in availablePatches) {
        if ([p shouldInstallOnMachineModel:macModel]) {
            [optimalPatches addObject:p];
        }
    }
    
    return optimalPatches;
}
-(NSString *)getMachineModel {
    NSString *macModel=@"";
    size_t len=0;
    sysctlbyname("hw.model", nil, &len, nil, 0);
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, nil, 0);
        macModel=[NSString stringWithFormat:@"%s", model];
        free(model);
    }
    return macModel;
}
-(NSString *)getCatalinaVolume {
    NSString *catVolume = [[self getAvailableVolumes] objectAtIndex:0];
    NSDate *latestDate = [NSDate dateWithTimeIntervalSince1970:0];
    for (NSString *volume in [self getAvailableVolumes]) {
        if ([self volumeContainsCatalina:[@"/Volumes" stringByAppendingPathComponent:volume]]) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"/Volumes/%@", volume] error:nil];
            
            NSDate *date = [attributes fileModificationDate];
            if ([date compare:latestDate] == NSOrderedDescending) {
                latestDate = date;
                catVolume = volume;
            }
        }
    }
    return catVolume;
}
-(BOOL)volumeContainsCatalina:(NSString *)volumePath {
    if ([[NSFileManager defaultManager]fileExistsAtPath:[volumePath stringByAppendingString:@"/System/Library/CoreServices/SystemVersion.plist"]] && ![[NSFileManager defaultManager]fileExistsAtPath:[volumePath stringByAppendingString:@"/System/Installation"]] && [[NSFileManager defaultManager]fileExistsAtPath:[volumePath stringByAppendingString:@"/Applications"]])
    {
        NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[volumePath stringByAppendingString:@"/System/Library/CoreServices/SystemVersion.plist"]];
        if ([[dict objectForKey:@"ProductVersion"]rangeOfString:@"10.15"].location != NSNotFound)
        {
            return YES;
        }
    }
    return NO;
}
-(NSArray *)getAvailableVolumes {
    NSMutableArray *availableVolumes = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:nil]];
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".DS_Store"])
    {
        [availableVolumes removeObjectAtIndex:0];
    }
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".Trashes"])
    {
        [availableVolumes removeObjectAtIndex:0];
    }
    return availableVolumes;
}
-(NSArray *)getAllModels {
    return [[macModels allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}
-(void)rebootSystemWithCacheRebuild:(BOOL)rebuildCaches onVolume:(NSString *)volumePath {
    if (rebuildCaches) {
        [self beginForceCacheRebuildOnVolume:volumePath];
    }
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/sbin/reboot"];
    [task launch];
}
-(void)beginForceCacheRebuildOnVolume:(NSString *)volumePath {
    
    NSTask *invalidate = [[NSTask alloc] init];
    [invalidate setLaunchPath:@"/usr/sbin/kextcache"];
    [invalidate setArguments:@[@"-i", volumePath]];
    [invalidate launch];
    [invalidate waitUntilExit];
}
-(void)updateDyldSharedCacheOnVolume:(NSString *)volumePath {
    
    NSTask *updateDyld = [[NSTask alloc] init];
    [updateDyld setLaunchPath:@"/usr/bin/update_dyld_shared_cache"];
    [updateDyld setArguments:@[@"-root", volumePath]];
    [updateDyld launch];
    [updateDyld waitUntilExit];
}
@end
