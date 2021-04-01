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
#import "STPrivilegedTask.h"


@protocol UpdateDelegate <NSObject>
@optional
-(void)updateDidFinishInstalling:(id)update withError:(int)err;
-(void)updateDidFinishUninstalling:(id)update withError:(int)err;
@end


typedef enum{
    actionInstall = 0,
    actionUninstall = 1
}action;

@interface Update : NSObject <NSURLConnectionDelegate>
{
    NSString *name;
    BOOL kextcacheRebuildRequired;
    NSString *size;
    NSInteger version;
    NSString *userVisiableName;
    NSString *description;
    NSString *URL;
    NSArray *supportedMachines;
    NSString *applicationSupportDirectory;
    action desiredAction;
    NSString *downloadingFile;
    NSFileHandle *downloadingFileHandle;
    NSDictionary *patchedFileSums;
    NSString *minSystemVersion;
}

@property (nonatomic, strong) id <UpdateDelegate> delegate;
-(id)init;
-(instancetype)initWithName:(NSString *)inName withUserVisiableName:(NSString *)inVisibleName withVersion:(NSInteger)inVer withDescription:(NSString *)inDescription withSize:(NSString *)inSize withURL:(NSString *)inURL withSupportedMachines:(NSArray *)inSupportedMachines kextcacheRebuildRequired:(BOOL)kextRebuild fileSumsDict:(NSDictionary *)fileSums withMinimumSystemVersion:(NSString *)minVersion;
-(NSString *)getSize;
-(NSInteger)getVersion;
-(NSString *)getName;
-(NSString *)getUserVisibleName;
-(NSString *)getDescription;
-(BOOL)isCompatibleWithThisMachine;
-(BOOL)isEqualTo:(Update *)u;
-(BOOL)isKextcacheRebuildRequired;
-(void)install;
-(BOOL)isPatchGood;


@end
