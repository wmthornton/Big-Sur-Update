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

#import <Foundation/Foundation.h>
#import "Update.h"
#import "PreferencesHandler.h"

typedef enum {
    connectionDownloadMetadata = 0,
    connectionDownloadUpdate = 1
}connection;

@protocol UpdateControllerDelegate <NSObject>
@optional
-(void)didRecieveUpdateData:(NSArray *)data;
-(void)updateDidFinishInstalling:(Update *)update withError:(int)err;
-(void)willInstallUpdate:(Update *)update;
-(void)installedUpdatesNeedKextcacheRebuild:(BOOL)rebuild;
-(void)kextcacheRebuildComplete;
-(void)connectionErrorOccurred;
@end


@protocol UpdateManagementDelegate <NSObject>
@optional
-(void)updateDidFinishBeingModified:(Update *)update withError:(int)err;
-(void)willModifyUpdate:(Update *)update;
-(void)modifiedUpdatesNeedKextcacheRebuild:(BOOL)rebuild;
-(void)kextcacheRebuildComplete;
-(void)connectionErrorOccurred;
@end

@interface UpdateController : NSObject <NSURLConnectionDelegate, UpdateDelegate>
{
    NSMutableArray *availableUpdates;
    NSDictionary *installedPatches;
    int connectionNum;
    NSMutableData *receivedData;
    long dlSize;
    NSString *applicationSupportDirectory;
    NSMutableArray *updatesToInstall;
    BOOL kextcacheRebuildRequired;
    NSDictionary *settings;
    NSMutableDictionary *installationReceipt;
}
@property (nonatomic, strong) id <UpdateControllerDelegate> delegate;
@property (nonatomic, strong) id <UpdateManagementDelegate> managerDelegate;

+(UpdateController *)sharedInstance;
-(void)updateData;
-(void)installUpdates:(NSArray *)updates;
-(void)rebuildKextcache;
-(NSDictionary *)getInstalledPatches;
-(NSArray *)getAllUpdates;
-(NSArray *)checkPatchIntegrityOfInstalledPatches;

@end
