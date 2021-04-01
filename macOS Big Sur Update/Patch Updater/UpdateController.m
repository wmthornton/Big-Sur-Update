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

#import "UpdateController.h"


@implementation UpdateController


-(id)init
{
    self=[super init];
    kextcacheRebuildRequired = NO;
    installedPatches = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/Application Support/macOS Catalina Patcher/installedPatches.plist"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    applicationSupportDirectory = [[paths firstObject] stringByAppendingPathComponent:@"macOS Catalina Patcher"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    settings = [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"settings.plist"]];
    [[PreferencesHandler sharedInstance] setUpdateDataURL:[settings objectForKey:@"updateDataURL"]];
    return self;
}

+(UpdateController *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static UpdateController *sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}
-(void)updateData
{
    connectionNum = connectionDownloadMetadata;
    NSURL* url = [NSURL URLWithString:[[PreferencesHandler sharedInstance] getUpdateDataURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection start];
}
-(NSArray *)getAvailableUpdates
{
    NSMutableArray *updates = [[NSMutableArray alloc] init];
    for (Update *u in availableUpdates)
    {
        BOOL added=NO;
        if ([installedPatches objectForKey:[u getName]])
        {
            added=YES;
            if ([u getVersion] > [[[installedPatches objectForKey:[u getName]] objectForKey:@"version"] intValue])
            {
                [updates addObject:u];
            }
        }
        if (!added && [u isCompatibleWithThisMachine])
        {
            [updates addObject:u];
        }
    }
    return updates;
}
- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    receivedData = [[NSMutableData alloc] initWithLength:0];
    dlSize = [response expectedContentLength];
}
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}
- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *localFile=@"";
    switch (connectionNum)
    {
        case connectionDownloadMetadata:
            localFile = [applicationSupportDirectory stringByAppendingPathComponent:@"updates.plist"];
            [receivedData writeToFile:localFile atomically:YES];
            availableUpdates = [[NSMutableArray alloc] init];
            [self loadUpdatesFromData:[[NSArray alloc] initWithContentsOfFile:[applicationSupportDirectory stringByAppendingPathComponent:@"updates.plist"]]];
            [[NSFileManager defaultManager] removeItemAtPath:[applicationSupportDirectory stringByAppendingPathComponent:@"updates.plist"] error:nil];
            [self.delegate didRecieveUpdateData:[self getAvailableUpdates]];
            break;
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate connectionErrorOccurred];
}
-(void)loadUpdatesFromData:(NSArray *)updatesTemp
{
    for (NSDictionary *update in updatesTemp)
    {
        Update *obj = [[Update alloc] initWithName:[update objectForKey:@"patchName"] withUserVisiableName:[update objectForKey:@"userVisibleName"] withVersion:[[update objectForKey:@"version"] integerValue] withDescription:[update objectForKey:@"description"] withSize:[update objectForKey:@"size"] withURL:[update objectForKey:@"patchURL"] withSupportedMachines:[update objectForKey:@"supportedMachines"] kextcacheRebuildRequired:[[update objectForKey:@"kextcacheRebuildRequired"] boolValue] fileSumsDict:[update objectForKey:@"patchedFileSums"] withMinimumSystemVersion:[update objectForKey:@"minSystemVersion"]];
        obj.delegate=self;
        [availableUpdates addObject:obj];
    }
}
-(void)updateDidFinishInstalling:(id)update withError:(int)err
{
    [self.delegate updateDidFinishInstalling:update withError:err];
    if (err == 0)
    {
        [updatesToInstall removeObjectAtIndex:0];
        if (updatesToInstall.count > 0)
        {
            [self.delegate willInstallUpdate:[updatesToInstall objectAtIndex:0]];
            if ([[updatesToInstall objectAtIndex:0] isKextcacheRebuildRequired])
            {
                kextcacheRebuildRequired=YES;
            }
            [installationReceipt setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[[updatesToInstall objectAtIndex:0] getVersion]] forKey:@"version"] forKey:[[updatesToInstall objectAtIndex:0] getName]];
            [[updatesToInstall objectAtIndex:0] install];
        }
        else
        {
            [installationReceipt writeToFile:[applicationSupportDirectory stringByAppendingPathComponent:@"installedPatches.plist"] atomically:YES];
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/macOS Catalina Patcher"])
            {
                STPrivilegedTask *md = [[STPrivilegedTask alloc] init];
                [md setLaunchPath:@"/bin/mkdir"];
                [md setArguments:[NSArray arrayWithObjects:@"/Library/Application Support/macOS Catalina Patcher", nil]];
                [md launch];
                [md waitUntilExit];
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/macOS Catalina Patcher/installedPatches.plist"])
            {
                STPrivilegedTask *chmod = [[STPrivilegedTask alloc] init];
                [chmod setLaunchPath:@"/bin/chmod"];
                [chmod setArguments:[NSArray arrayWithObjects:@"777", @"/Library/Application Support/macOS Catalina Patcher/installedPatches.plist", nil]];
                [chmod launch];
                [chmod waitUntilExit];
            }
            STPrivilegedTask *moveReceipt = [[STPrivilegedTask alloc] init];
            [moveReceipt setLaunchPath:@"/bin/mv"];
            [moveReceipt setArguments:[NSArray arrayWithObjects:[applicationSupportDirectory stringByAppendingPathComponent:@"installedPatches.plist"], @"/Library/Application Support/macOS Catalina Patcher/installedPatches.plist", nil]];
            [moveReceipt launch];
            [moveReceipt waitUntilExit];
            [self.delegate installedUpdatesNeedKextcacheRebuild:kextcacheRebuildRequired];
        }
    }
}
-(void)installUpdates:(NSArray *)updates
{
    installationReceipt = [[NSMutableDictionary alloc] initWithDictionary:installedPatches];
    updatesToInstall = [[NSMutableArray alloc] initWithArray:updates];
    if (updatesToInstall.count > 0)
    {
        STPrivilegedTask *mountRW = [[STPrivilegedTask alloc] init];
        [mountRW setArguments:@[@"-uw", @"/"]];
        [mountRW setLaunchPath:@"/sbin/mount"];
        int err = [mountRW launch];
        if (err) {
            [self.delegate updateDidFinishInstalling:[updatesToInstall objectAtIndex:0] withError:err];
        }
        else {
            [mountRW waitUntilExit];
            [self.delegate willInstallUpdate:[updatesToInstall objectAtIndex:0]];
            if ([[updatesToInstall objectAtIndex:0] isKextcacheRebuildRequired])
            {
                kextcacheRebuildRequired=YES;
            }
            [installationReceipt setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[[updatesToInstall objectAtIndex:0] getVersion]] forKey:@"version"] forKey:[[updatesToInstall objectAtIndex:0] getName]];
            [[updatesToInstall objectAtIndex:0] install];
        }
    }
    else
    {
        [self.delegate installedUpdatesNeedKextcacheRebuild:kextcacheRebuildRequired];
    }
}
-(void)rebuildKextcache
{
    STPrivilegedTask *systemCacheRebuild = [[STPrivilegedTask alloc] init];
    [systemCacheRebuild setLaunchPath:@"/usr/sbin/kextcache"];
    [systemCacheRebuild setArguments:[NSArray arrayWithObject:@"-system-caches"]];
    [systemCacheRebuild launch];
    [systemCacheRebuild waitUntilExit];
    STPrivilegedTask *prelinkedKernelRebuild = [[STPrivilegedTask alloc] init];
    [prelinkedKernelRebuild setLaunchPath:@"/usr/sbin/kextcache"];
    [prelinkedKernelRebuild setArguments:[NSArray arrayWithObject:@"-system-prelinked-kernel"]];
    [prelinkedKernelRebuild launch];
    [prelinkedKernelRebuild waitUntilExit];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate kextcacheRebuildComplete];
    });
}
-(NSDictionary *)getInstalledPatches
{
    return installedPatches;
}
-(NSArray *)getAllUpdates
{
    return availableUpdates;
}
-(NSArray *)checkPatchIntegrityOfInstalledPatches
{
    NSMutableArray *failedPatches = [[NSMutableArray alloc] init];
    for (Update *u in availableUpdates)
    {
        if ([installedPatches objectForKey:[u getName]])
        {
            if (![u isPatchGood])
            {
                [failedPatches addObject:u];
            }
        }
    }
    return failedPatches;
}
@end
