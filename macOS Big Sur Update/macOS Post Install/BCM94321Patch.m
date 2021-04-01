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

#import "BCM94321Patch.h"

@implementation BCM94321Patch

-(id)init {
    self = [super init];
    [self setID:@"bcm94321Patch"];
    [self setVersion:0];
    [self setName:@"Broadcom BCM4321 WiFi Support Patch"];
    return self;
}
-(int)applyToVolume:(NSString *)volumePath {
    int ret = 0;
    if ([self hasBCM94321]) {
        ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"patchedkexts/bcm4321"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    }
    return ret;
}

-(BOOL)hasBCM94321
{
    CFMutableDictionaryRef matchingDict;
    io_iterator_t iter;
    kern_return_t kr;
    io_registry_entry_t device;
    
    matchingDict = IOServiceMatching("IOService");
    if (matchingDict == NULL)
    {
        printf("Failed to match dict\n");
        return -1;
    }
    
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iter);
    if (kr != KERN_SUCCESS)
    {
        printf("Failed to get matching services\n");
        return -1;
    }
    
    const UInt8 NUM_SUBSYS_IDS = 7;
    const UInt8 vendorMatch [2] = {0xE4, 0x14}; //Broadcom - 0x14E4
    const UInt8 subMatch [NUM_SUBSYS_IDS] = {0x8C, 0x9D, 0x87, 0x88, 0x8B, 0x89, 0x90};
    BOOL match = NO;
    while ((device = IOIteratorNext(iter)))
    {
        CFMutableDictionaryRef serviceDictionary;
        if (IORegistryEntryCreateCFProperties(device,
                                              &serviceDictionary,
                                              kCFAllocatorDefault,
                                              kNilOptions) != kIOReturnSuccess)
        {
            IOObjectRelease(device);
            continue;
        }
        
        CFDataRef vendorID = CFDictionaryGetValue(serviceDictionary, CFSTR("vendor-id"));
        
        if (vendorID)
        {
            
            const UInt8 *ven = CFDataGetBytePtr(vendorID);
            if (ven[0] == vendorMatch[0] && ven[1] == vendorMatch[1])
            {
                CFDataRef subsystemID = CFDictionaryGetValue(serviceDictionary, CFSTR("subsystem-id"));
                const UInt8 *sub = CFDataGetBytePtr(subsystemID);
                for (int i=0; i<NUM_SUBSYS_IDS; i++)
                {
                    if (subMatch[i] == sub[0])
                    {
                        printf("FOUND MATCH: VEN: %X%X, DEV: %X\n", ven[0], ven[1], sub[0]);
                        match = YES;
                    }
                }
            }
        }
        CFRelease(serviceDictionary);
        IOObjectRelease(device);
    }
    IOObjectRelease(iter);
    return match;
}
@end
