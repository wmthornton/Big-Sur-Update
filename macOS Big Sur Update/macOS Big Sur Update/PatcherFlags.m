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

#import "PatcherFlags.h"

@implementation PatcherFlags

-(id)init {
    self = [super init];
    shouldUseAPFSBooter = YES;
    shouldAutoApplyPostInstall = YES;
    return self;
}
-(id)initWithPatcherFlags:(PatcherFlags *)o {
    self = [self init];
    shouldUseAPFSBooter = [o shouldUseAPFSBooter];
    shouldAutoApplyPostInstall = [o shouldAutoApplyPostInstall];
    return self;
}
+ (PatcherFlags *)sharedInstance {
    static PatcherFlags *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
-(void)setShouldUseAPFSBooter:(BOOL)shouldUse {
    shouldUseAPFSBooter = shouldUse;
}
-(void)setShouldAutoApplyPostInstall:(BOOL)shouldAutoApply {
    shouldAutoApplyPostInstall = shouldAutoApply;
}
-(BOOL)shouldUseAPFSBooter {
    return shouldUseAPFSBooter;
}
-(BOOL)shouldAutoApplyPostInstall {
    return shouldAutoApplyPostInstall;
}
-(void)saveToDirectory:(NSString *)path {
    NSDictionary *flags = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:shouldUseAPFSBooter], [NSNumber numberWithBool:shouldAutoApplyPostInstall]] forKeys:@[@kShouldUseAPFSBooter, @kShouldAutoApplyPostInstall]];
    [flags writeToFile:[path stringByAppendingPathComponent:@PatcherFlagsFile] atomically:YES];
}
-(void)loadFromDirectory:(NSString *)path {
    NSDictionary *flags = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@PatcherFlagsFile]];
    if (flags) {
        shouldUseAPFSBooter = [[flags objectForKey:@kShouldUseAPFSBooter] boolValue];
        shouldAutoApplyPostInstall = [[flags objectForKey:@kShouldAutoApplyPostInstall] boolValue];
    }
}
@end
