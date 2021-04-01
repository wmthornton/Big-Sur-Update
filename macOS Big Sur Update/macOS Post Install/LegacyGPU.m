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

#import "LegacyGPU.h"

@implementation LegacyGPU
-(id)init {
    self = [super init];
    [self setID:@"legacyGPU"];
    [self setVersion:13];
    [self setName:@"Legacy Video Card Patch"];
    return self;
}
-(int)applyToVolume:(NSString *)volumePath {
    int ret = 0;
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/kexts"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    if (ret) {
        return ret;
    }
    
    //No errors for FWs as they will always return one
    
    [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/frameworks"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Frameworks"]];

    [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/privateframeworks"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/PrivateFrameworks"]];
    
    //Copy wrappers
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/wrappers/CoreDisplay"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Frameworks/CoreDisplay.framework/Versions/A"]];
    if (ret) {
        return ret;
    }
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/wrappers/SkyLight"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/PrivateFrameworks/SkyLight.framework/Versions/A"]];
    if (ret) {
        return ret;
    }
    
    //Copy kexts
    ret = [self copyFile:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/IOSurface"] toDirectory:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions/IOSurface.kext/Contents/MacOS"]];
    if (ret) {
        return ret;
    }
    
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/intelarrandalegraphics"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    if (ret) {
        return ret;
    }
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/intelsandybridgegraphics"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    if (ret) {
        return ret;
    }
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/legacyamd"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    if (ret) {
        return ret;
    }
    ret = [self copyFilesFromDirectory:[resourcePath stringByAppendingPathComponent:@"videocardpatches/legacynvidia"] toPath:[volumePath stringByAppendingPathComponent:@"System/Library/Extensions"]];
    if (ret) {
        return ret;
    }
    
    //Copy misc
    ret = [self copyFile:[resourcePath stringByAppendingPathComponent:@"videocardpatches/gfxshared/misc/MonitorPanels"] toDirectory:[volumePath stringByAppendingPathComponent:@"System/Library"]];
    
    return ret;
}

@end
