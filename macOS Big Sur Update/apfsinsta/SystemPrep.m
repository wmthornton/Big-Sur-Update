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

#import "SystemPrep.h"

@implementation SystemPrep

-(id)init {
    self = [super init];
    resourcePath = [self locateResourcesPath];
    return self;
}
-(NSString *)locateResourcesPath {
    NSString *expectedPathInstallerEnv = @"/Applications/Utilities/macOS Post Install.app/Contents/Resources";
    if ([[NSFileManager defaultManager] fileExistsAtPath:expectedPathInstallerEnv]) {
        return expectedPathInstallerEnv;
    }
    return @"/private/tmp";
}
-(NSString *)locateTargetVolume {
    for (NSString *volume in [self getAvailableVolumes]) {
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[@"/Volumes" stringByAppendingPathComponent:volume] error:nil]) {
            if ([file rangeOfString:@"Install"].location != NSNotFound && [file rangeOfString:@"Data"].location != NSNotFound) {
                NSDictionary *index = [[NSDictionary alloc] initWithContentsOfFile:[[[@"/Volumes" stringByAppendingPathComponent:volume] stringByAppendingPathComponent:file] stringByAppendingPathComponent:@"index.sproduct"]];
                NSArray *packages = [index objectForKey:@"Packages"];
                for (NSDictionary *d in packages) {
                    NSString *version = [d objectForKey:@"Version"];
                    if ([version rangeOfString:@"10.15"].location != NSNotFound) {
                        return volume;
                    }
                }
            }
        }
    }
    //failsafe
    for (NSString *volume in [self getAvailableVolumes]) {
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[@"/Volumes" stringByAppendingPathComponent:volume] error:nil]) {
            if ([file rangeOfString:@"Install"].location != NSNotFound && [file rangeOfString:@"Data"].location != NSNotFound) {
                return volume;
            }
        }
    }
    return @"";
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

-(BOOL)systemNeedsAPFSBooter {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[@"/" stringByAppendingPathComponent:@PatcherFlagsFile]]) {
        [[PatcherFlags sharedInstance] loadFromDirectory:@"/"];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[@"/private/tmp" stringByAppendingPathComponent:@PatcherFlagsFile]]) {
        [[PatcherFlags sharedInstance] loadFromDirectory:@"/private/tmp"];
    }
    
    NSString *machineModel = [self getMachineModel];
    NSDictionary *macModelsDict = [[NSDictionary alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"macmodels.plist"]];
    NSDictionary *modelPatches = [macModelsDict objectForKey:machineModel];
    if (modelPatches) {
        if ([[modelPatches objectForKey:@kModelNeedsAPFSPatch] boolValue]) {
            if ([[PatcherFlags sharedInstance] shouldUseAPFSBooter]) {
                return YES;
            }
        }
    }
    return NO;
}
-(void)setNoCompatCheckNVRAM {
    NSTask *nvramSet = [[NSTask alloc] init];
    [nvramSet setLaunchPath:@"/usr/sbin/nvram"];
    [nvramSet setArguments:@[@"boot-args=-no_compat_check"]];
    [nvramSet launch];
    [nvramSet waitUntilExit];
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
-(void)installAPFSBooterForInstallerVolumeAtPath:(NSString *)volumePath {
    NSString *bsdName = [[APFSManager sharedInstance] getAPFSPhysicalStoreForVolumeAtPath:volumePath];
    NSString *diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSString *ESPDisk = [NSString stringWithFormat:@"disk%lds1", diskNum];
    NSString *volumeUUID = [[APFSManager sharedInstance] getUUIDOfVolumeAtPath:volumePath];
    
    NSString *scriptHeader = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptHeader.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *mainScript = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptMain.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *scriptToWrite = [NSString stringWithFormat:@"%@\nset macOSBootFile \"%@\"\nset targetUUID \"%@\"\n%@", scriptHeader, @InstallerPrebootBootFileLocation, volumeUUID, mainScript];
    
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:@[@"mount", ESPDisk]];
    [mount launch];
    [mount waitUntilExit];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/EFI/EFI/BOOT"])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/Volumes/EFI/EFI/BOOT" withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [scriptToWrite writeToFile:@"/Volumes/EFI/EFI/BOOT/startup.nsh" atomically:YES encoding:NSUnicodeStringEncoding error:nil];
    [self copyFile:[resourcePath stringByAppendingPathComponent:@"BOOTX64.efi"] toDirectory:@"/Volumes/EFI/EFI/BOOT"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/macOS Base System/usr/standalone/i386/apfs.efi"]) {
        [self copyFile:@"/Volumes/macOS Base System/usr/standalone/i386/apfs.efi" toDirectory:@"/Volumes/EFI/EFI"];
    } else {
        [self copyFile:@"/usr/standalone/i386/apfs.efi" toDirectory:@"/Volumes/EFI/EFI"];
    }
    
    /*NSTask *unmount = [[NSTask alloc] init];
    [unmount setLaunchPath:@"/usr/sbin/diskutil"];
    [unmount setArguments:@[@"unmount", ESPDisk]];
    [unmount launch];
    [unmount waitUntilExit];*/
    
}
-(void)blessESPForBooter {
    NSTask *bless = [[NSTask alloc] init];
    [bless setLaunchPath:@"/usr/sbin/bless"];
    [bless setArguments:@[@"--mount", @"/Volumes/EFI", @"--setBoot", @"--file", @"/Volumes/EFI/EFI/BOOT/BOOTX64.efi", @"--shortform"]];
    [bless launch];
    [bless waitUntilExit];
}
-(int)copyFile:(NSString *)filePath toDirectory:(NSString *)dirPath {
    NSTask *copy = [[NSTask alloc] init];
    [copy setLaunchPath:@"/bin/cp"];
    [copy setArguments:@[@"-r", filePath, dirPath]];
    [copy launch];
    [copy waitUntilExit];
    return [copy terminationStatus];
}
-(void)setNoCompatCheckInstallerBootPlistOnVolumePath:(NSString *)volumePath {
    NSString *prebootDisk = [[APFSManager sharedInstance] getPrebootVolumeforAPFSVolumeAtPath:volumePath];
    NSString *volumeUUID = [[APFSManager sharedInstance] getUUIDOfVolumeAtPath:volumePath];
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:@[@"mount", prebootDisk]];
    [mount launch];
    [mount waitUntilExit];
    
    NSMutableDictionary *bootPlist = [[NSMutableDictionary alloc]initWithContentsOfFile:[volumePath stringByAppendingString:@InstallerBootPlistFileLocation]];
    NSString *kernelFlags = [bootPlist objectForKey:@"Kernel Flags"];
    if ([kernelFlags isEqualToString:@""])
    {
        kernelFlags = @"-no_compat_check";
    }
    else if ([kernelFlags rangeOfString:@"-no_compat_check"].location == NSNotFound)
    {
        kernelFlags = [kernelFlags stringByAppendingString:@" -no_compat_check"];
    }
    [bootPlist setObject:kernelFlags forKey:@"Kernel Flags"];
    [bootPlist writeToFile:[volumePath stringByAppendingString:@InstallerBootPlistFileLocation] atomically:YES];
    [bootPlist writeToFile:[NSString stringWithFormat:@"/Volumes/Preboot/%@/%@", volumeUUID, @InstallerPrebootBootPlistFileLocation] atomically:YES];
    
    NSTask *unmount = [[NSTask alloc] init];
    [unmount setLaunchPath:@"/usr/sbin/diskutil"];
    [unmount setArguments:@[@"unmount", prebootDisk]];
    [unmount launch];
    [unmount waitUntilExit];
}
-(BOOL)hasRunThisBoot {
    NSDictionary *prepFlags = [[NSDictionary alloc] initWithContentsOfFile:[@"/private/tmp" stringByAppendingPathComponent:@PrepFlagsFile]];
    if (prepFlags) {
        if ([[prepFlags objectForKey:@kToolHasRun] boolValue]) {
            return YES;
        }
    }
    return NO;
}
-(void)setToolHasRunThisBoot:(BOOL)hasRun {
    NSDictionary *prepFlags = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithBool:hasRun]] forKeys:@[@kToolHasRun]];
    [prepFlags writeToFile:[@"/private/tmp" stringByAppendingPathComponent:@PrepFlagsFile] atomically:YES];
}
@end
