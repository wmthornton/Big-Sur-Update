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

#import "PatchManager.h"

@implementation PatchManager

-(id)init {
    self = [super init];
    return self;
}

-(int)copyFile:(NSString *)filePath toDirectory:(NSString *)dirPath {
    NSTask *copy = [[NSTask alloc] init];
    [copy setLaunchPath:@"/bin/cp"];
    [copy setArguments:@[@"-R", filePath, dirPath]];
    NSPipe *out = [NSPipe pipe];
    [copy setStandardOutput:out];
    [copy setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [copy launch];
    [copy waitUntilExit];
    return [copy terminationStatus];
}
-(int)setPermsOnFile:(NSString *)path {
    int err = 0;
    NSTask *chmod = [[NSTask alloc] init];
    [chmod setLaunchPath:@"/bin/chmod"];
    [chmod setArguments:@[@"-R", @"755", path]];
    NSPipe *out = [NSPipe pipe];
    [chmod setStandardOutput:out];
    [chmod setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [chmod launch];
    [chmod waitUntilExit];
    err = [chmod terminationStatus];
    if (err) {
        return err;
    }
    
    NSTask *chown = [[NSTask alloc] init];
    [chown setLaunchPath:@"/usr/sbin/chown"];
    [chown setArguments:@[@"-R", @"0:0", path]];
    out = [NSPipe pipe];
    [chown setStandardOutput:out];
    [chown setStandardError:out];
    [[LoggingManager sharedInstance] setOutputPipe:out];
    [chown launch];
    [chown waitUntilExit];
    err = [chown terminationStatus];
    return err;
}
@end
