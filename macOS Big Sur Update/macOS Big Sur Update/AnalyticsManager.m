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

#import "AnalyticsManager.h"

@implementation AnalyticsManager

-(id)init {
    self = [super init];
    return self;
}
+ (AnalyticsManager *)sharedInstance {
    static AnalyticsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void)postAnalyticsOfPatcherMode:(int)mode usingInstallerAppVersion:(NSString *)version withError:(int)err {
    NSString *errNum = [NSString stringWithFormat:@"%d", err];
    NSString *patcherMode = [NSString stringWithFormat:@"%d", mode];
    NSString *macModel = [self getMachineModel];
    NSString *systemVersion = [self getCurrentSystemVersion];
    NSString *sysID = [self getHashOfString:[self getSystemUUID]];
    NSString *log = [[CatalinaPatcherLoggingManager sharedInstance] getCurrentLogText];
    NSString *patcherVersion = [self getAppVersion];
    
    NSString *post = [NSString stringWithFormat:@"key=%@&id=%@&error=%@&mode=%@&model=%@&sysver=%@&appver=%@&installerver=%@&log=%@", @AnalyticsKey, sysID, errNum, patcherMode, macModel, systemVersion, patcherVersion, version, log];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@AnalyticsURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
}
-(NSString *)getMachineModel {
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
    return macModel;
}
-(NSString *)getCurrentSystemVersion {
    NSDictionary *systemVersion = [[NSDictionary alloc] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    return [systemVersion objectForKey:@"ProductVersion"];
}
- (NSString *)getSystemUUID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert)
        return nil;
    
    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    if (!serialNumberAsCFString)
        return nil;
    
    IOObjectRelease(platformExpert);
    return (__bridge NSString *)(serialNumberAsCFString);
}
-(NSString *)getHashOfString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
-(NSString *)getAppVersion {
    NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]];
    return [info objectForKey:@"CFBundleShortVersionString"];
}
@end
