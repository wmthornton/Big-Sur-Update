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

#import "InstallerPatcher.h"

@implementation InstallerPatcher

-(id)init {
    self = [super init];
    return self;
}

-(int)shadowMountDMGAtPath:(NSString *)path toMountpoint:(NSString *)mntpt {
    int err = 0;
    NSString *shadowFilePath = [path stringByAppendingPathExtension:@"shadow"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:shadowFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:shadowFilePath error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:mntpt withIntermediateDirectories:YES attributes:nil error:nil];
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/bin/hdiutil"];
    NSArray *mountArgs = [[NSArray alloc] initWithObjects:@"attach", @"-owners", @"on", path, @"-noverify", @"-nobrowse", @"-mountpoint", mntpt, @"-shadow",nil];
    [mount setArguments:mountArgs];
    NSPipe *out = [NSPipe pipe];
    [mount setStandardOutput:out];
    [mount setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [mount launch];
    [mount waitUntilExit];
    err = [mount terminationStatus];
    return err;
}
-(int)copyPatchedBaseSystemFilesFromDirectory:(NSString *)dir toBSMount:(NSString *)mnt {
    
    int err = 0;
    NSString *appPath = [mnt stringByAppendingPathComponent:[self locateInstallerAppAtPath:mnt]];
    
    NSArray *paths = @[[mnt stringByAppendingPathComponent:@"Library/Extensions/DisableLibraryValidation.kext"], [mnt stringByAppendingPathComponent:@"Library/Extensions/LegacyUSBInjector.kext"], [mnt stringByAppendingPathComponent:@"Library/Extensions/SIPManager.kext"], [mnt stringByAppendingPathComponent:@"System/Library/PrelinkedKernels/prelinkedkernel"], [mnt stringByAppendingPathComponent:@"usr/libexec/brtool"], [mnt stringByAppendingPathComponent:@"System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], [appPath stringByAppendingPathComponent:@"Contents/Frameworks/OSInstallerSetup.framework/Versions/A/Frameworks/OSInstallerSetupInternal.framework/Versions/A/OSInstallerSetupInternal"], [appPath stringByAppendingPathComponent:@"Contents/Frameworks/OSInstallerSetup.framework/Versions/A/Resources/osishelperd"], [mnt stringByAppendingPathComponent:@"/sbin/apfsbless"], [mnt stringByAppendingPathComponent:@"/sbin/apfsinsta"], [mnt stringByAppendingPathComponent:@"/sbin/runposti"]];
    
    for (NSString *path in paths) {
        err = [self copyFile:[dir stringByAppendingPathComponent:[path lastPathComponent]] toDirectory:[path stringByDeletingLastPathComponent]];
        if (err) {
            return err;
        }
    }
    
    [self copyFile:[dir stringByAppendingPathComponent:@"macOS Post Install.app"] toDirectory:[mnt stringByAppendingPathComponent:@"Applications/Utilities"]];
    [self copyFile:[dir stringByAppendingPathComponent:@"APFSFirmwareVerification.app"] toDirectory:[mnt stringByAppendingPathComponent:@"System/Library/CoreServices"]];
    [self copyFile:[dir stringByAppendingPathComponent:@"com.dosdude1.APFSFirmwareVerification.plist"] toDirectory:[mnt stringByAppendingPathComponent:@"/System/Library/LaunchDaemons"]];
    
    [[NSFileManager defaultManager] copyItemAtPath:[dir stringByAppendingPathComponent:@"VolumeIcon.icns"] toPath:[mnt stringByAppendingPathComponent:@".VolumeIcon.icns"] error:nil];
    
    return err;
}
-(int)setBaseSystemPermissionsOnVolume:(NSString *)path {
    
    return [self setPermsOnFile:[path stringByAppendingPathComponent:@"Library/Extensions"]];
    
}
-(int)copyPatchedInstallESDFilesFromDirectory:(NSString *)dir toESDMount:(NSString *)mnt {
    int err = 0;
    NSArray *paths = @[[mnt stringByAppendingPathComponent:@"Packages/OSInstall.mpkg"]];
    for (NSString *path in paths) {
        err = [self copyFile:[dir stringByAppendingPathComponent:[path lastPathComponent]] toDirectory:[path stringByDeletingLastPathComponent]];
        if (err) {
            return err;
        }
    }
    return err;
}
-(int)saveModifiedShadowDMG:(NSString *)dmgPath mountedAt:(NSString *)mountPt toPath:(NSString *)path {
    int err = 0;
    NSString *bsdName = [self getBSDNameForVolumePath:mountPt];
    NSTask *detach  = [[NSTask alloc] init];
    [detach setLaunchPath:@"/usr/bin/hdiutil"];
    [detach setArguments:@[@"detach", bsdName]];
    NSPipe *out = [NSPipe pipe];
    [detach setStandardOutput:out];
    [detach setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [detach launch];
    [detach waitUntilExit];
    err = [detach terminationStatus];
    if (err) {
        return err;
    }
    
    NSTask *saveImage = [[NSTask alloc] init];
    [saveImage setLaunchPath:@"/usr/bin/hdiutil"];
    [saveImage setArguments:@[@"convert", @"-format", @"UDZO", @"-o", path, dmgPath, @"-shadow"]];
    out = [NSPipe pipe];
    [saveImage setStandardOutput:out];
    [saveImage setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [saveImage launch];
    [saveImage waitUntilExit];
    err = [saveImage terminationStatus];
     
    return err;
}
-(int)restoreBaseSystemDMG:(NSString *)dmgPath toVolume:(NSString *)volumePath {
    int err = 0;
    NSString *volumeBSD = [self getBSDNameForVolumePath:volumePath];
    NSTask *restore = [[NSTask alloc] init];
    [restore setLaunchPath:@"/usr/sbin/asr"];
    
    NSArray *args = [[NSArray alloc] initWithObjects:@"restore", @"--source", dmgPath, @"--target", volumePath, @"--noprompt", @"--noverify", @"--erase", nil];
    SInt32 versMin;
    Gestalt(gestaltSystemVersionMinor, &versMin);
    if (versMin >= 14) {
        args = [[NSArray alloc] initWithObjects:@"restore", @"--source", dmgPath, @"--target", volumePath, @"--noprompt", @"--noverify", @"--erase", @"--no-personalization", nil];
    }
    
    [restore setArguments:args];
    NSPipe *out = [NSPipe pipe];
    [restore setStandardOutput:out];
    [restore setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [restore launch];
    [restore waitUntilExit];
    err = [restore terminationStatus];
    if (err) {
        return err;
    }
    
    NSTask *renameVolume = [[NSTask alloc] init];
    [renameVolume setLaunchPath:@"/usr/sbin/diskutil"];
    [renameVolume setArguments:[NSArray arrayWithObjects:@"rename", volumeBSD, [volumePath lastPathComponent], nil]];
    out = [NSPipe pipe];
    [renameVolume setStandardOutput:out];
    [renameVolume setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [renameVolume launch];
    [renameVolume waitUntilExit];
    err = [renameVolume terminationStatus];
    return err;
}
-(int)copySharedSupportDirectoryFilesFrom:(NSString *)ssPath toPath:(NSString *)path {
    int err = 0;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:ssPath error:nil];
    for (NSString *file in files)
    {
        if ([file rangeOfString:@"BaseSystem.dmg"].location == NSNotFound && [file rangeOfString:@"InstallESD.dmg"].location == NSNotFound)
        {
            err = [self copyFile:[ssPath stringByAppendingPathComponent:file] toDirectory:path];
            if (err) {
                return err;
            }
        }
    }
    return err;
}

-(NSString *)getBSDNameForVolumePath:(NSString *)volumePath
{
    NSTask *getDiskInfo = [[NSTask alloc]init];
    [getDiskInfo setLaunchPath:@"/usr/sbin/diskutil"];
    [getDiskInfo setArguments:[NSArray arrayWithObjects:@"info", volumePath, nil]];
    NSPipe * out = [NSPipe pipe];
    [getDiskInfo setStandardOutput:out];
    [getDiskInfo launch];
    [getDiskInfo waitUntilExit];
    NSFileHandle * read = [out fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSInteger i = [stringRead rangeOfString:@"Device Identifier:"].location;
    if (i != NSNotFound)
    {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *bsdName = [[temp substringFromIndex:26] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return bsdName;
    }
    return @"";
}
-(NSString *)locateInstallerAppAtPath:(NSString *)path {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *file in files)
    {
        if ([file rangeOfString:@"Install macOS"].location != NSNotFound)
        {
            return file;
        }
    }
    return @"";
}
-(int)preventVolumeFromDisplayingWindowOnMount:(NSString *)volumePath {
    NSTask *bless = [[NSTask alloc] init];
    [bless setLaunchPath:@"/usr/sbin/bless"];
    [bless setArguments:@[@"-folder", volumePath]];
    [bless launch];
    [bless waitUntilExit];
    return 0;
}

-(int)addPostInstallEntryToUtilitiesOnVolume:(NSString *)volumePath {
    NSString *utilitiesFile = [volumePath stringByAppendingPathComponent:@"System/Installation/CDIS/macOS Utilities.app/Contents/Resources/Utilities.plist"];
    NSMutableDictionary *utilities = [[NSMutableDictionary alloc] initWithContentsOfFile:utilitiesFile];
    NSMutableArray *buttons = [utilities objectForKey:@"Buttons"];
    NSDictionary *postInstallButton = [[NSDictionary alloc] initWithObjects:@[@"/Applications/Utilities/macOS Post Install.app", @"Apply post-install patches to a volume containing a Catalina install.", @"/Applications/Utilities/macOS Post Install.app/Contents/MacOS/macOS Post Install", @"macOS Post Install"] forKeys:@[@"BundlePath", @"DescriptionKey", @"Path", @"TitleKey"]];
    [buttons addObject:postInstallButton];
    [utilities setObject:buttons forKey:@"Buttons"];
    [utilities writeToFile:utilitiesFile atomically:YES];
    return 0;
}
-(int)setBootPlistOnVolume:(NSString *)volumePath {
    NSString *bootPlistFile = [volumePath stringByAppendingPathComponent:@"Library/Preferences/SystemConfiguration/com.apple.Boot.plist"];
    NSMutableDictionary *bootPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:bootPlistFile];
    [bootPlist setObject:@"-no_compat_check" forKey:@"Kernel Flags"];
    [bootPlist writeToFile:bootPlistFile atomically:YES];
    return 0;
}
-(int)setPlatformSupportPlistOnVolume:(NSString *)volumePath usingSourcePlist:(NSString *)plistPath {
    const NSString *kSupportedBoardIDs = @"SupportedBoardIds";
    const NSString *kSupportedModels = @"SupportedModelProperties";
    
    NSDictionary *legacyPlatformSupport = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    NSArray *legacyBoardSupport = [legacyPlatformSupport objectForKey:kSupportedBoardIDs];
    NSArray *legacyModelSupport = [legacyPlatformSupport objectForKey:kSupportedModels];
    
    NSMutableDictionary *platformSupport = [[NSMutableDictionary alloc] initWithContentsOfFile:[volumePath stringByAppendingPathComponent:@"System/Library/CoreServices/PlatformSupport.plist"]];
    NSMutableArray *boardSupport = [platformSupport objectForKey:kSupportedBoardIDs];
    NSMutableArray *modelSupport = [platformSupport objectForKey:kSupportedModels];
    
    for (NSString *boardID in legacyBoardSupport) {
        if (![boardSupport containsObject:boardID]) {
            [boardSupport addObject:boardID];
        }
    }
    
    for (NSString *modelID in legacyModelSupport) {
        if (![modelSupport containsObject:modelID]) {
            [modelSupport addObject:modelID];
        }
    }
    
    [platformSupport setObject:boardSupport forKey:kSupportedBoardIDs];
    [platformSupport setObject:modelSupport forKey:kSupportedModels];
    
    [platformSupport writeToFile:[volumePath stringByAppendingPathComponent:@"System/Library/CoreServices/PlatformSupport.plist"] atomically:YES];
    return 0;
}
@end
