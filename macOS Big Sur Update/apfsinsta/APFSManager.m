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

#import "APFSManager.h"

@implementation APFSManager

-(id)init {
    self = [super init];
    return self;
}

+ (APFSManager *)sharedInstance {
    static APFSManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(NSString *)getAPFSPhysicalStoreForVolumeAtPath:(NSString *)volumePath
{
    NSTask *getDiskInfo = [[NSTask alloc]init];
    [getDiskInfo setLaunchPath:@"/usr/sbin/diskutil"];
    [getDiskInfo setArguments:[NSArray arrayWithObjects:@"list", volumePath, nil]];
    NSPipe * out = [NSPipe pipe];
    [getDiskInfo setStandardOutput:out];
    [getDiskInfo launch];
    [getDiskInfo waitUntilExit];
    NSFileHandle * read = [out fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSInteger i = [stringRead rangeOfString:@"Physical Store"].location;
    if (i != NSNotFound)
    {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *diskName = [[temp substringFromIndex:15] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return diskName;
    }
    return @"";
}
-(NSString *)getUUIDOfVolumeAtPath:(NSString *)volumePath
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
    NSInteger i = [stringRead rangeOfString:@"Volume UUID:"].location;
    if (i != NSNotFound)
    {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *UUID = [[temp substringFromIndex:26] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return UUID;
    }
    return @"";
}
-(NSString *)getPrebootVolumeforAPFSVolumeAtPath:(NSString *)volumePath
{
    NSTask *getDiskInfo = [[NSTask alloc]init];
    [getDiskInfo setLaunchPath:@"/usr/sbin/diskutil"];
    [getDiskInfo setArguments:[NSArray arrayWithObjects:@"list", volumePath, nil]];
    NSPipe * out = [NSPipe pipe];
    [getDiskInfo setStandardOutput:out];
    [getDiskInfo launch];
    [getDiskInfo waitUntilExit];
    NSFileHandle * read = [out fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSInteger i = [stringRead rangeOfString:@"Preboot"].location;
    if (i != NSNotFound)
    {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *diskName = [[temp substringFromIndex:35] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return diskName;
    }
    return @"";
}
-(NSString *)getRecoveryVolumeforAPFSVolumeAtPath:(NSString *)volumePath
{
    NSTask *getDiskInfo = [[NSTask alloc]init];
    [getDiskInfo setLaunchPath:@"/usr/sbin/diskutil"];
    [getDiskInfo setArguments:[NSArray arrayWithObjects:@"list", volumePath, nil]];
    NSPipe * out = [NSPipe pipe];
    [getDiskInfo setStandardOutput:out];
    [getDiskInfo launch];
    [getDiskInfo waitUntilExit];
    NSFileHandle * read = [out fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSInteger i = [stringRead rangeOfString:@"Recovery"].location;
    if (i != NSNotFound)
    {
        NSString *temp = [stringRead substringFromIndex:i];
        temp = [temp substringToIndex:[temp rangeOfString:@"\n"].location];
        NSString *diskName = [[temp substringFromIndex:35] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return diskName;
    }
    return @"";
}
-(BOOL)romSupportsAPFS {
    io_registry_entry_t romEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/rom@0");
    if (romEntry || (romEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/rom@e0000")) != 0) {
        CFNumberRef apfsProp = IORegistryEntryCreateCFProperty(romEntry, CFSTR("firmware-features"), kCFAllocatorDefault, 0);
        if (!apfsProp) {
            NSLog(@"Could not check for APFS BootROM Support: Failed to create IORegistryEntry.");
            return NO;
        }
        unsigned long long value;
        CFNumberGetValue(apfsProp, kCFNumberSInt64Type, &value);
        NSLog(@"firmware-features: %llx", value);
        CFRelease(apfsProp);
        if ((value & 0x180000) != 0) {
            return YES;
        }
        
    } else {
        NSLog(@"Could not check for APFS BootROM Support: Failed to open IORegistryEntry.");
        return NO;
    }
    return NO;
}
@end
