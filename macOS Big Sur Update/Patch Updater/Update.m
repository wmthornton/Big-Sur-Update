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

#import "Update.h"
#include <sys/sysctl.h>
#include <CommonCrypto/CommonDigest.h>

@implementation Update

-(id)init
{
    self=[super init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    applicationSupportDirectory = [[paths firstObject] stringByAppendingPathComponent:@"macOS Catalina Patcher"];
    return self;
}
-(instancetype)initWithName:(NSString *)inName withUserVisiableName:(NSString *)inVisibleName withVersion:(NSInteger)inVer withDescription:(NSString *)inDescription withSize:(NSString *)inSize withURL:(NSString *)inURL withSupportedMachines:(NSArray *)inSupportedMachines kextcacheRebuildRequired:(BOOL)kextRebuild fileSumsDict:(NSDictionary *)fileSums withMinimumSystemVersion:(NSString *)minVersion
{
    self=[self init];
    name = inName;
    userVisiableName = inVisibleName;
    version = inVer;
    description = inDescription;
    size = inSize;
    URL = inURL;
    supportedMachines = inSupportedMachines;
    kextcacheRebuildRequired = kextRebuild;
    patchedFileSums = fileSums;
    minSystemVersion = minVersion;
    return self;
}
-(NSString *)getSize
{
    return size;
}
-(NSInteger)getVersion
{
    return version;
}
-(NSString *)getName
{
    return name;
}
-(NSString *)getUserVisibleName
{
    return userVisiableName;
}
-(NSString *)getDescription
{
    return description;
}
-(BOOL)isKextcacheRebuildRequired
{
    return kextcacheRebuildRequired;
}
-(BOOL)isCompatibleWithThisMachine
{
    if ([self isCompatibleWithCurrentSystemVersion]) {
        if (supportedMachines.count == 1 && [[supportedMachines objectAtIndex:0] isEqualToString:@"all"])
        {
            return YES;
        }
        NSString *macModel=@"";
        size_t len=0;
        sysctlbyname("hw.model", nil, &len, nil, 0);
        if (len)
        {
            char *model = malloc(len*sizeof(char));
            sysctlbyname("hw.model", model, &len, nil, 0);
            macModel=[NSString stringWithFormat:@"%s", model];
            free(model);
        }
        for (NSString *model in supportedMachines)
        {
            if ([macModel isEqualToString:model])
            {
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)isEqualTo:(Update *)u
{
    return [name isEqualToString:[u getName]];
}
-(void)install
{
    desiredAction = actionInstall;
    downloadingFile = [applicationSupportDirectory stringByAppendingPathComponent:@"update.zip"];
    NSURL* url = [NSURL URLWithString:URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection start];
}
- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    if (desiredAction == actionInstall)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[applicationSupportDirectory stringByAppendingPathComponent:@"update"]])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[applicationSupportDirectory stringByAppendingPathComponent:@"update"] error:nil];
        }
        [[NSFileManager defaultManager] createFileAtPath:downloadingFile contents:nil attributes:nil];
        downloadingFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:downloadingFile];
    }
    else if (desiredAction == actionUninstall)
    {
        
    }
}
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [downloadingFileHandle writeData:data];
}
- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    [downloadingFileHandle closeFile];
    if (desiredAction == actionInstall)
    {
        [self performSelectorInBackground:@selector(extractAndInstall) withObject:nil];
    }
    else if (desiredAction == actionUninstall)
    {
        
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (desiredAction == actionInstall)
    {
        [self.delegate updateDidFinishInstalling:self withError:-1];
    }
    else if (desiredAction == actionUninstall)
    {
        
    }
}
-(void)extractAndInstall
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/unzip"];
    [task setArguments:[NSArray arrayWithObjects:@"-o", [applicationSupportDirectory stringByAppendingPathComponent:@"update.zip"], @"-d", applicationSupportDirectory, nil]];
    [task launch];
    [task waitUntilExit];
    NSTask *chmod = [[NSTask alloc] init];
    [chmod setLaunchPath:@"/bin/chmod"];
    [chmod setArguments:[NSArray arrayWithObjects:@"+x", [applicationSupportDirectory stringByAppendingPathComponent:@"/update/install.sh"], nil]];
    [chmod launch];
    [chmod waitUntilExit];
    STPrivilegedTask *install = [[STPrivilegedTask alloc] init];
    [install setCurrentDirectoryPath:[applicationSupportDirectory stringByAppendingPathComponent:@"update"]];
    [install setArguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], nil]];
    [install setLaunchPath:[applicationSupportDirectory stringByAppendingPathComponent:@"update/install.sh"]];
    int err = [install launch];
    [install waitUntilExit];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate updateDidFinishInstalling:self withError:err];
    });
}
-(BOOL)isPatchGood
{
    BOOL good = YES;
    for (NSString *key in patchedFileSums.allKeys)
    {
        if (![[self checkHashOfFile:key] isEqualToString:[patchedFileSums objectForKey:key]])
        {
            good = NO;
        }
    }
    return good;
}
-(NSString *)checkHashOfFile:(NSString *)filePath
{
    NSData *file = [NSData dataWithContentsOfFile:filePath];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(file.bytes, (CC_LONG)file.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
-(BOOL)isCompatibleWithCurrentSystemVersion {
    if (minSystemVersion) {
        if ([minSystemVersion isEqualToString:@"all"]) {
            return YES;
        }
        SInt32 versMaj, versMin, versBugFix;
        Gestalt(gestaltSystemVersionMajor, &versMaj);
        Gestalt(gestaltSystemVersionMinor, &versMin);
        Gestalt(gestaltSystemVersionBugFix, &versBugFix);
        NSArray *verNums = [minSystemVersion componentsSeparatedByString:@"."];
        int minMajorVer = [[verNums objectAtIndex:0] intValue];
        int minMinorVer = [[verNums objectAtIndex:1] intValue];
        int minBugfixVer = [[verNums objectAtIndex:2] intValue];
        return (versMaj >= minMajorVer && versMin >= minMinorVer && versBugFix >= minBugfixVer);
    }
    return YES;
}
@end
