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

#import "APFSPrefpaneHelper.h"

@implementation APFSPrefpaneHelper
-(id)init {
    self = [super init];
    shouldKeepRunning = YES;
    currentUUID = @"";
    return self;
}
-(void)startIPCService {
    connection = [[NSConnection alloc] init];
    [connection setRootObject:self];
    [connection registerName:@SERVER_ID];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (shouldKeepRunning && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}
-(void)setResourcesPath:(NSString *)path {
    resourcePath = path;
}
-(NSString *)getBSDNameForVolumePath:(NSString *)volumePath {
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
    if (i != NSNotFound) {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *bsdName = [[temp substringFromIndex:26] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return bsdName;
    }
    return @"";
}
-(NSArray *)getAvailableVolumesForDisk:(NSString *)diskName {
    NSString *bsdName = [self getAPFSPhysicalStoreForDisk:diskName];
    diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSString *physicalStoreDisk = [NSString stringWithFormat:@"disk%ld", diskNum];
    NSMutableArray *vols = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:nil]];
    NSMutableArray *availVols = [[NSMutableArray alloc] init];
    if ([[vols objectAtIndex:0] isEqualToString:@".DS_Store"]) {
        [vols removeObjectAtIndex:0];
    }
    if ([[vols objectAtIndex:0] isEqualToString:@".Trashes"]) {
        [vols removeObjectAtIndex:0];
    }
    for (NSString *vol in vols) {
        if ([[self getAPFSPhysicalStoreForDisk:[@"/Volumes" stringByAppendingPathComponent:vol]] rangeOfString:physicalStoreDisk].location != NSNotFound && [self doesVolumeContainMacOS:vol] && [self isVolumeAPFS:[@"/Volumes" stringByAppendingPathComponent:vol]]) {
            [availVols addObject:vol];
        }
    }
    return [NSArray arrayWithArray:availVols];
}
-(NSString *)getUUIDOfVolumeAtPath:(NSString *)volumePath {
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
    NSInteger i = [stringRead rangeOfString:@"Volume UUID:"].location;
    if (i != NSNotFound) {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *UUID = [[temp substringFromIndex:26] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return UUID;
    }
    return @"";
}
-(NSString *)getAPFSPhysicalStoreForDisk:(NSString *)disk {
    NSTask *getDiskInfo = [[NSTask alloc]init];
    [getDiskInfo setLaunchPath:@"/usr/sbin/diskutil"];
    [getDiskInfo setArguments:[NSArray arrayWithObjects:@"list", disk, nil]];
    NSPipe * out = [NSPipe pipe];
    [getDiskInfo setStandardOutput:out];
    [getDiskInfo launch];
    [getDiskInfo waitUntilExit];
    NSFileHandle * read = [out fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSInteger i = [stringRead rangeOfString:@"Physical Store"].location;
    if (i != NSNotFound) {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *diskName = [[temp substringFromIndex:15] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return diskName;
    }
    return @"";
}
-(int)mountESPForRootDisk {
    int err = 0;
    NSString *bsdName = [self getAPFSPhysicalStoreForDisk:@"/"];
    NSString *diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSArray *args = [[NSArray alloc]initWithObjects:@"mount", [NSString stringWithFormat:@"disk%lds1", diskNum], nil];
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:args];
    [mount launch];
    [mount waitUntilExit];
    err = [mount terminationStatus];
    return err;
}
-(int)unmountESPForRootDisk {
    int err = 0;
    NSString *bsdName = [self getAPFSPhysicalStoreForDisk:@"/"];
    NSString *diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSArray *args = [[NSArray alloc]initWithObjects:@"unmount", [NSString stringWithFormat:@"disk%lds1", diskNum], nil];
    NSTask *mount = [[NSTask alloc] init];
    [mount setLaunchPath:@"/usr/sbin/diskutil"];
    [mount setArguments:args];
    [mount launch];
    [mount waitUntilExit];
    err = [mount terminationStatus];
    return err;
}
-(NSString *)getCurrentBootUUIDForRootDisk {
    [self mountESPForRootDisk];
    NSString *EFIScript = [NSString stringWithContentsOfFile:@"/Volumes/EFI/EFI/BOOT/startup.nsh" encoding:NSUnicodeStringEncoding error:nil];
    NSString *bootUUID = [EFIScript substringFromIndex:[EFIScript rangeOfString:@"targetUUID"].location + 12];
    bootUUID = [bootUUID substringToIndex:[bootUUID rangeOfString:@"\""].location];
    [self unmountESPForRootDisk];
    return bootUUID;
}
-(int)setCurrentBootUUID:(NSString *)volumeUUID {
    int err = 0;
    err = [self mountESPForRootDisk];
    if (err) {
        return err;
    }
    NSString *scriptHeader = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptHeader.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *mainScript = [NSString stringWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"EFIScriptMain.txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString *scriptToWrite = [NSString stringWithFormat:@"%@\nset macOSBootFile \"%@\"\nset targetUUID \"%@\"\n%@", scriptHeader, @BootFileLocation, volumeUUID, mainScript];
    [scriptToWrite writeToFile:@"/Volumes/EFI/EFI/BOOT/startup.nsh" atomically:YES encoding:NSUnicodeStringEncoding error:nil];
    NSTask *bless = [[NSTask alloc] init];
    [bless setLaunchPath:@"/usr/sbin/bless"];
    [bless setArguments:[NSArray arrayWithObjects:@"--mount", @"/Volumes/EFI", @"--setBoot", @"--file", @"/Volumes/EFI/EFI/BOOT/BOOTX64.efi", @"--shortform", nil]];
    [bless launch];
    [bless waitUntilExit];
    err = [bless terminationStatus];
    if (err) {
        return err;
    }
    err = [self unmountESPForRootDisk];
    return err;
}
-(BOOL)isVolumeAPFS:(NSString *)volumePath {
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
    NSInteger i = [stringRead rangeOfString:@"Type (Bundle):"].location;
    if (i != NSNotFound) {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *volumeType =  [temp substringFromIndex:26];
        if ([volumeType rangeOfString:@"apfs"].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)doesVolumeContainMacOS:(NSString *)volume {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[@"/Volumes" stringByAppendingPathComponent:volume] stringByAppendingPathComponent:@"/System/Library/CoreServices/boot.efi"]];
}

-(void)beginLoadingAvailableVolumesForRoot {
    NSString *selectedVolume = @"";
    NSString *bsdName = [self getBSDNameForVolumePath:@"/"];
    NSString *diskName = [bsdName substringFromIndex:4];
    NSInteger diskNum = [diskName substringToIndex:[bsdName rangeOfString:@"s"].location-1].integerValue;
    NSArray *availableVolumes = [self getAvailableVolumesForDisk:[NSString stringWithFormat:@"disk%ld", diskNum]];
    if ([currentUUID isEqualToString:@""])
    {
        currentUUID = [self getCurrentBootUUIDForRootDisk];
    }
    BOOL selectedVolumeFound = NO;
    for (int i=0; i<availableVolumes.count; i++)
    {
        if ([[self getUUIDOfVolumeAtPath:[@"/Volumes" stringByAppendingPathComponent:[availableVolumes objectAtIndex:i]]] isEqualToString:currentUUID])
        {
            selectedVolumeFound = YES;
            selectedVolume = [availableVolumes objectAtIndex:i];
        }
    }
    [self.delegate didLoadVolumes:availableVolumes withCurrentBootVolume:selectedVolume withError:0];
}

-(void)beginSettingBootVolume:(NSString *)volumeName {
    NSString *uuid = [self getUUIDOfVolumeAtPath:[@"/Volumes" stringByAppendingPathComponent:volumeName]];
    currentUUID = uuid;
    [self setCurrentBootUUID:currentUUID];
    [self.delegate didSetStartupVolumeWithError:0];
}


@end
