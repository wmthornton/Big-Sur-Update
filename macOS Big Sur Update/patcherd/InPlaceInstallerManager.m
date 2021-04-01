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

#import "InPlaceInstallerManager.h"

@implementation InPlaceInstallerManager

-(id)init {
    self = [super init];
    return self;
}
-(int)launchInstallerAppAtPath:(NSString *)appPath {
    NSTask *open = [[NSTask alloc] init];
    [open setLaunchPath:@"/usr/bin/open"];
    [open setArguments:@[appPath]];
    NSPipe *out = [NSPipe pipe];
    [open setStandardOutput:out];
    [open setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [open launch];
    [open waitUntilExit];
    return [open terminationStatus];
}
-(int)loadDisableLibValKext:(NSString *)kextPath {
    
    int err = 0;
    
    NSString *tmpKextDir = @"/private/tmp/lbv.kext";
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpKextDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpKextDir error:nil];
    }
    [[NSFileManager defaultManager] copyItemAtPath:kextPath toPath:tmpKextDir error:nil];
    
    err = [self setPermsOnFile:tmpKextDir];
    
    if (err) {
        return err;
    }
    
    NSTask *kextload = [[NSTask alloc] init];
    [kextload setLaunchPath:@"/sbin/kextload"];
    [kextload setArguments:@[tmpKextDir]];
    NSPipe *out = [NSPipe pipe];
    [kextload setStandardOutput:out];
    [kextload setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [kextload launch];
    [kextload waitUntilExit];
    err = [kextload terminationStatus];
    return err;
}
-(BOOL)systemNeedsDisableLibVal {
    SInt32 versMin;
    Gestalt(gestaltSystemVersionMinor, &versMin);
    return (versMin >= 12);
}
-(int)prepareRootFSForInstallationUsingResources:(NSString *)resourcePath {
    int err = 0;
    SInt32 versMin;
    Gestalt(gestaltSystemVersionMinor, &versMin);
    if (versMin >= 15) {
        err = [self mountRootFSReadWrite];
        if (err) {
            return err;
        }
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"apfsbless"] toDirectory:@"/sbin"];
    if (err) {
        return err;
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"apfsinsta"] toDirectory:@"/sbin"];
    if (err) {
        return err;
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"BOOTX64.efi"] toDirectory:@"/private/tmp"];
    if (err) {
        return err;
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptHeader.txt"] toDirectory:@"/private/tmp"];
    if (err) {
        return err;
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptMain.txt"] toDirectory:@"/private/tmp"];
    if (err) {
        return err;
    }
    err = [self copyFile:[resourcePath stringByAppendingPathComponent:@"macmodels.plist"] toDirectory:@"/private/tmp"];
    if (err) {
        return err;
    }
    return err;
}
-(BOOL)isSIPEnabled {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/csrutil"]) {
        NSTask *csrutil = [[NSTask alloc]init];
        [csrutil setLaunchPath:@"/usr/bin/csrutil"];
        [csrutil setArguments:[NSArray arrayWithObject:@"status"]];
        NSPipe * out = [NSPipe pipe];
        [csrutil setStandardOutput:out];
        [csrutil launch];
        [csrutil waitUntilExit];
        NSFileHandle * read = [out fileHandleForReading];
        NSData * dataRead = [read readDataToEndOfFile];
        NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        if ([stringRead rangeOfString:@"Custom Configuration"].location != NSNotFound) {
            if ([stringRead rangeOfString:@"Kext Signing: disabled"].location == NSNotFound) {
                return YES;
            }
        }
        else if ([stringRead rangeOfString:@"enabled"].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}
-(int)mountRootFSReadWrite {
    int err = 0;
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/sbin/mount"];
    [mount setArguments:@[@"-uw", @"/"]];
    [mount launch];
    [mount waitUntilExit];
    err = [mount terminationStatus];
    return err;
}
@end
