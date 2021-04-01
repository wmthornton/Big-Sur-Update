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

#import "Patch.h"

@implementation Patch

-(id)init {
    self = [super init];
    identifier = @"";
    version = 0;
    shouldInstall = NO;
    resourcePath = [[NSBundle mainBundle] resourcePath];
    [self loadMacModels];
    return self;
}
-(void)loadMacModels {
    macModels = [[NSDictionary alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"macmodels.plist"]];
}
-(int)applyToVolume:(NSString *)volumePath {
    return 0;
}
-(NSString *)getID {
    return identifier;
}
-(void)setID:(NSString *)inID {
    identifier = inID;
}
-(int)getVersion {
    return version;
}
-(void)setVersion:(int)ver {
    version = ver;
}
-(NSString *)getName {
    return visibleName;
}
-(void)setName:(NSString *)name {
    visibleName = name;
}

-(int)copyFile:(NSString *)filePath toDirectory:(NSString *)dirPath {
    NSTask *copy = [[NSTask alloc] init];
    [copy setLaunchPath:@"/bin/cp"];
    [copy setArguments:@[@"-r", filePath, dirPath]];
    [copy launch];
    [copy waitUntilExit];
    return [copy terminationStatus];
}
-(int)copyFilesFromDirectory:(NSString *)dirPath toPath:(NSString *)targetPath {
    int ret = 0;
    NSArray *filesToCopy = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    
    for (NSString *file in filesToCopy) {
        NSTask *copy = [[NSTask alloc] init];
        [copy setLaunchPath:@"/bin/cp"];
        [copy setArguments:@[@"-r", [dirPath stringByAppendingPathComponent:file], targetPath]];
        [copy launch];
        [copy waitUntilExit];
        ret = [copy terminationStatus];
        if (ret) {
            return ret;
        }
    }
    return ret;
}
-(BOOL)shouldBeInstalled {
    return shouldInstall;
}
-(void)setShouldBeInstalled:(BOOL)install {
    shouldInstall = install;
}
-(NSString *)getDataVolumeForMainVolume:(NSString *)mainVolume {
    return [mainVolume stringByAppendingString:@" - Data"];
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
-(NSString *)getUIActionString {
    return @"Applying";
}
-(BOOL)shouldInstallOnMachineModel:(NSString *)model {
    NSDictionary *machinePatches = [macModels objectForKey:model];
    if (machinePatches) {
        if ([[machinePatches objectForKey:identifier] boolValue]) {
            return YES;
        }
    }
    return NO;
}
-(void)setBootPlistAtPath:(NSString *)plistPath {
    NSMutableDictionary *bootPlist = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    NSString *kernelFlags = [bootPlist objectForKey:@"Kernel Flags"];
    if ([kernelFlags isEqualToString:@""]) {
        kernelFlags = @"-no_compat_check";
    }
    else if ([kernelFlags rangeOfString:@"-no_compat_check"].location == NSNotFound) {
        kernelFlags = [kernelFlags stringByAppendingString:@" -no_compat_check"];
    }
    [bootPlist setObject:kernelFlags forKey:@"Kernel Flags"];
    [bootPlist writeToFile:plistPath atomically:YES];
}
-(void)setPlatformSupportPlistAtPath:(NSString *)plistPath {
    
    const NSString *kSupportedBoardIDs = @"SupportedBoardIds";
    const NSString *kSupportedModels = @"SupportedModelProperties";
    
    NSDictionary *legacyPlatformSupport = [[NSDictionary alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"PlatformSupportLegacy.plist"]];
    NSArray *legacyBoardSupport = [legacyPlatformSupport objectForKey:kSupportedBoardIDs];
    NSArray *legacyModelSupport = [legacyPlatformSupport objectForKey:kSupportedModels];
    
    NSMutableDictionary *platformSupport = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
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
    
    [platformSupport writeToFile:plistPath atomically:YES];
}
@end
