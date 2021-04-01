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
#import "SystemPrep.h"


int main(int argc, const char * argv[])
{
    //This binary takes the place of "bless".
    @autoreleasepool {
        
        SystemPrep *p = [[SystemPrep alloc] init];
        
        if ([p systemNeedsAPFSBooter]) {
            
            NSMutableArray *blessArgs = [[NSMutableArray alloc] init];
            for (int i=1; i<argc; i++) {
                [blessArgs addObject:[NSString stringWithUTF8String:argv[i]]];
            }
            NSTask *bless = [[NSTask alloc] init];
            [bless setLaunchPath:@"/usr/sbin/bless"];
            [bless setArguments:blessArgs];
            [bless launch];
            [bless waitUntilExit];
            
            [p blessESPForBooter];
            
        } else {
            NSMutableArray *blessArgs = [[NSMutableArray alloc] init];
            for (int i=1; i<argc; i++) {
                [blessArgs addObject:[NSString stringWithUTF8String:argv[i]]];
            }
            NSTask *bless = [[NSTask alloc] init];
            [bless setLaunchPath:@"/usr/sbin/bless"];
            [bless setArguments:blessArgs];
            [bless launch];
            [bless waitUntilExit];
            return [bless terminationStatus];
        }
    }
    return 0;
}

