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

#import "APFSPatch.h"

@implementation APFSPatch

-(id)init {
    self = [super init];
    [self setID:@"needsAPFSPatch"];
    [self setVersion:0];
    [self setName:@"APFS Patch"];
    return self;
}
-(int)applyToVolume:(NSString *)volumePath {
    int ret = 0;
    
    
    NSString *bsdName = [[APFSManager sharedInstance] getAPFSPhysicalStoreForVolumeAtPath:volumePath];
    NSString *diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSString *ESPDisk = [NSString stringWithFormat:@"disk%lds1", diskNum];
    NSString *volumeUUID = [[APFSManager sharedInstance] getUUIDOfVolumeAtPath:volumePath];
    
    NSString *scriptHeader = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptHeader.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *mainScript = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptMain.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *scriptToWrite = [NSString stringWithFormat:@"%@\nset macOSBootFile \"%@\"\nset targetUUID \"%@\"\n%@", scriptHeader, @BootFileLocation, volumeUUID, mainScript];
    

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
    [self copyFile:[volumePath stringByAppendingPathComponent:@"usr/standalone/i386/apfs.efi"] toDirectory:@"/Volumes/EFI/EFI"];
    
    NSTask *bless = [[NSTask alloc] init];
    [bless setLaunchPath:@"/usr/sbin/bless"];
    [bless setArguments:@[@"--mount", @"/Volumes/EFI", @"--setBoot", @"--file", @"/Volumes/EFI/EFI/BOOT/BOOTX64.efi", @"--shortform"]];
    [bless launch];
    [bless waitUntilExit];
    
    NSTask *unmount = [[NSTask alloc] init];
    [unmount setLaunchPath:@"/usr/sbin/diskutil"];
    [unmount setArguments:@[@"unmount", ESPDisk]];
    [unmount launch];
    [unmount waitUntilExit];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[volumePath stringByAppendingPathComponent:@"usr/local/sbin"]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[volumePath stringByAppendingPathComponent:@"usr/local/sbin"] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [self copyFile:[resourcePath stringByAppendingPathComponent:@"apfshelperd"] toDirectory:[volumePath stringByAppendingPathComponent:@"usr/local/sbin"]];
    [self copyFile:[resourcePath stringByAppendingPathComponent:@"com.dosdude1.apfshelperd.plist"] toDirectory:[volumePath stringByAppendingPathComponent:@"Library/LaunchDaemons"]];
    [self copyFile:[resourcePath stringByAppendingPathComponent:@"APFS Boot Selector.prefPane"] toDirectory:[volumePath stringByAppendingPathComponent:@"Library/PreferencePanes"]];
    
    [self setPermissionsOnDirectory:[volumePath stringByAppendingPathComponent:@"Library/LaunchDaemons/com.dosdude1.apfshelperd.plist"]];
    
    return ret;
}
-(BOOL)shouldInstallOnMachineModel:(NSString *)model {
    NSDictionary *machinePatches = [macModels objectForKey:model];
    if (machinePatches) {
        if ([[machinePatches objectForKey:identifier] boolValue]) {
            [[PatcherFlags sharedInstance] loadFromDirectory:@"/"];
            if ([[PatcherFlags sharedInstance] shouldUseAPFSBooter]) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return NO;
}
@end
