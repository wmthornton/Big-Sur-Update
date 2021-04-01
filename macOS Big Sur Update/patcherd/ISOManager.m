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

#import "ISOManager.h"

@implementation ISOManager

-(id)init {
    self = [super init];
    return self;
}

-(int)createISOImageAtPath:(NSString *)path withVolumeName:(NSString *)name usingContentsOfDirectory:(NSString *)dirPath {
    //hdiutil create ~/Desktop/newimage.dmg -volname "New Disk Image" -size 1g -format UDRW -srcfolder ~/Desktop/myfolder
    NSTask *createImg = [[NSTask alloc] init];
    [createImg setLaunchPath:@"/usr/bin/hdiutil"];
    [createImg setArguments:@[@"create", path, @"-volname", name, @"-format", @"UDTO", @"-srcfolder", dirPath]];
    NSPipe *out = [NSPipe pipe];
    [createImg setStandardOutput:out];
    [createImg setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [createImg launch];
    [createImg waitUntilExit];
    if ([createImg terminationStatus] != 0)
    {
        return isoErrCreatingBaseImage;
    }
    return 0;
}
-(int)copyBaseSystemInstallerFilesFromDirectory:(NSString *)dir toDirectory:(NSString *)targetDir {
    int err = 0;
    NSString *appFile = [self locateInstallerAppAtPath:dir];
    
    NSFileManager *man = [NSFileManager defaultManager];
    [man createDirectoryAtPath:[targetDir stringByAppendingPathComponent:@"Library/Preferences/SystemConfiguration"] withIntermediateDirectories:YES attributes:nil error:nil];
    [man createDirectoryAtPath:[targetDir stringByAppendingPathComponent:@"System/Library/CoreServices"] withIntermediateDirectories:YES attributes:nil error:nil];
    [man createDirectoryAtPath:[targetDir stringByAppendingPathComponent:@"usr/standalone/i386"] withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSArray *paths = @[appFile, @"System/Library/PrelinkedKernels", @"System/Library/CoreServices/SystemVersion.plist", @"System/Library/CoreServices/BridgeVersion.bin", @"System/Library/CoreServices/PlatformSupport.plist", @"usr/standalone/i386/SecureBoot.bundle"];
    
    for (NSString *path in paths) {
        err = [self copyFile:[dir stringByAppendingPathComponent:path] toDirectory:[targetDir stringByAppendingPathComponent:[path stringByDeletingLastPathComponent]]];
        if (err) {
            return err;
        }
    }
    
    NSArray *csFiles = [man contentsOfDirectoryAtPath:[dir stringByAppendingPathComponent:@"System/Library/CoreServices"] error:nil];
    for (NSString *file in csFiles) {
        if ([file rangeOfString:@"boot"].location != NSNotFound) {
            err = [self copyFile:[[dir stringByAppendingPathComponent:@"System/Library/CoreServices"] stringByAppendingPathComponent:file] toDirectory:[targetDir stringByAppendingPathComponent:@"System/Library/CoreServices"]];
            if (err) {
                return err;
            }
        }
    }

    return err;
}
-(int)setupBootPlistForBSBootOnVolume:(NSString *)path {
    NSMutableDictionary *boot = [[NSMutableDictionary alloc] init];
    NSString *appName = [self locateInstallerAppAtPath:path];
    NSString *BSPath = [@"/" stringByAppendingPathComponent:[appName stringByAppendingPathComponent:@"Contents/SharedSupport/BaseSystem.dmg"]];
    NSString *bootArgs = [NSString stringWithFormat:@"-no_compat_check root-dmg=file://%@", [BSPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [boot setObject:bootArgs forKey:@"Kernel Flags"];
    [boot writeToFile:[path stringByAppendingPathComponent:@"Library/Preferences/SystemConfiguration/com.apple.Boot.plist"] atomically:YES];
    return 0;
}
-(int)writeIAPhysicalMediaFlagWithAppName:(NSString *)name toVolume:(NSString *)path {
    NSMutableDictionary *IAFlags = [[NSMutableDictionary alloc] init];
    [IAFlags setObject:name forKey:@"AppName"];
    [IAFlags writeToFile:[path stringByAppendingPathComponent:@".IAPhysicalMedia"] atomically:YES];
    return 0;
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
@end
