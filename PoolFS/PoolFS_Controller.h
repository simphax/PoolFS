//
//  PoolFS_Controller.h
//  PoolFS
//
//  Created by Rory Sinclair on 02/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "PoolFS_Filesystem.h"

@class GMUserFileSystem;
@class PoolFS_Controller;

@interface PoolFS_Controller : NSObject {
  GMUserFileSystem* fs_;
  PoolFS_Filesystem* fs_delegate_;
}

- (void)userPreferencesUpdated:(NSNotification*)notification;

@end

NSString* const kPoolFSPreferencesUpdated = @"PoolFSPreferencesUpdated";
NSString* const observedObject = @"com.mungler.PoolFS.PrefPaneTarget";