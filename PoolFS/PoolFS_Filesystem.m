// ================================================================
// Copyright (C) 2007 Google Inc.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ================================================================
//
//  LoopbackFS.m
//  LoopbackFS
//
//  Created by ted on 12/12/07.
//
// This is a simple but complete example filesystem that mounts a local 
// directory. You can modify this to see how the Finder reacts to returning
// specific error codes or not implementing a particular GMUserFileSystem
// operation.
//
// For example, you can mount "/tmp" in /Volumes/loop. Note: It is 
// probably not a good idea to mount "/" through this filesystem.

#define TAG_PREFIX "\u200B"
#define TAG_COLOR 1

#import <sys/xattr.h>
#import <sys/stat.h>
#import "PoolFS_Filesystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import "NSError+POSIX.h"
#import "NodeManager.h"
#import "LocationSelectWindow.h"

@implementation PoolFS_Filesystem

- (id)initWithPoolManager:(NodeManager *)manager {
	if ((self = [super init])) {
		_manager = [manager retain];
	}
    
	return self;
}

- (void) dealloc {
	[_manager release];
	[super dealloc];
}

#pragma mark GUI

-(NSString *) chooseLocationModalForPath:(NSString *) path
{
    LocationSelectWindow *locationSelectWindow = [[LocationSelectWindow alloc] init];
    
    NSArray *rootNodes = [_manager availableRootNodes];
    
    NSDictionary *returnDict = [locationSelectWindow runModalWidthNodes:rootNodes forPath:path];
    
    if(returnDict != nil)
    {
        NSString *result = [returnDict objectForKey:@"selectedNode"];
        
        NSLog(@"Selected node in modal: %@",result);
        return result;
    }
    else
    {
        return nil;
    }
}


#pragma mark Moving an Item

//TODO: Won't work with redundant path
- (BOOL)moveItemAtPath:(NSString *)source 
                toPath:(NSString *)destination
                 error:(NSError **)error {
	
	NSLog(@"moveItemAtPath:%@ toPath:%@ START-----------------------", source, destination);
    
	// move the source path to the dest path on the source node (faster I/O)
	NSArray* sourceNodePaths = [_manager nodePathsForPath:source error:error];
	/*
	for (id sourceNodePath in sourceNodePaths) {
		
		NSString* node = [_manager nodeForPath:source error:error];
		
		NSString* destNodePath = [node stringByAppendingString:destination];
		
		[_manager createDirectoriesForNodePath:destNodePath error:error];
		
		// We use rename directly here since NSFileManager can sometimes fail to 
		// rename and return non-posix error codes.
		
		//NSLog(@"Moving: %@ to %@", sourceNodePath, destNodePath);
		
		int ret = rename([sourceNodePath UTF8String], [destNodePath UTF8String]);
		if ( ret < 0 ) {
			NSLog(@"failed to move with error code %d", ret);
			*error = [NSError errorWithPOSIXCode:errno];
		}
	}
	*/
	// next we check the number of source nodes == number of dest nodes 
	NSArray* destNodePaths = [_manager nodePathsForPath:destination error:error createNew:YES forNodePaths:sourceNodePaths];

	//int sourceCount = [sourceNodePaths count];
	//int destCount = [destNodePaths count];

	//if (sourceCount != destCount) {
	/*
		if (sourceCount > destCount) {
			// we're moving an item from a redundant directory to a non-redundant directory, purge one copy
			NSLog(@"moving from redundant to non-redundant - not yet implemented!");
		} else {
			// we're moving an item from a non-redundant directory to a redundant directory, create a redundant copy
			NSLog(@"moving from non-redundant to redundant");
			
			for (id destNodePath in destNodePaths) {
                /*
				if (![sourceNodePaths containsObject:destNodePath]) {
					//[_manager createDirectoriesForNodePath:destNodePath error:error];
					NSLog(@"copying from %@ to %@",[sourceNodePaths objectAtIndex:0], destNodePath);
					[[NSFileManager defaultManager] copyItemAtPath:[sourceNodePaths objectAtIndex:0] toPath:destNodePath error:error];
				}
                 */
                //[_manager createDirectoriesForNodePath:destNodePath error:error];
                NSString *destNodePath  = [destNodePaths objectAtIndex:0];
                //Lets try to just rename it first.
                NSString* p_src = [sourceNodePaths objectAtIndex:0];
                NSString* p_dst = destNodePath;
                int ret = rename([p_src UTF8String], [p_dst UTF8String]);
                if ( ret < 0 ) {
                    //We failed to rename
                    if ( error ) {
                        *error = [NSError errorWithPOSIXCode:errno];
                    }
                    if(errno == EXDEV) //Cross-device link error. This means the file is at another drive
                    {
                        //TODO: This might be dangerous because there is a risk of data loss if it crashes midway. And I guess some metadata may get lost.
                        [_manager createDirectoriesForNodePath:destNodePath error:error];
                        NSLog(@"replacing %@ with %@",destNodePath,[sourceNodePaths objectAtIndex:0]);
                        [[NSFileManager defaultManager] removeItemAtPath:destNodePath error:error];
                        if(![[NSFileManager defaultManager] copyItemAtPath:[sourceNodePaths objectAtIndex:0] toPath:destNodePath error:error]) return NO;
                        [[NSFileManager defaultManager] removeItemAtPath:[sourceNodePaths objectAtIndex:0] error:error];
                    }
                    else
                    {
                        return NO;
                    }
                }
			//}
        //}
	//}
	
	NSLog(@"moveItemAtPath:%@ toPath:%@ END-----------------------", source, destination);
	
	return YES; //TODO: handle errors properly
}

#pragma mark Removing an Item

- (BOOL)removeDirectoryAtPath:(NSString *)path error:(NSError **)error {
	// We need to special-case directories here and use the bsd API since 
	// NSFileManager will happily do a recursive remove :-(
	
	NSLog(@"removeDirectoryAtPath:%@",path);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error];
	
	//NSLog(@"found %d nodePaths for path: %@ - deleting", [nodePaths count], path);
	
	for (id nodePath in nodePaths) {
		
		int ret = rmdir([nodePath UTF8String]);
		if (ret < 0) {
			*error = [NSError errorWithPOSIXCode:errno];
			//return NO;
			//TODO: do something with this error
		}		
	}
	
	return YES; // TODO: handle errors properly
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
	
	NSLog(@"removeItemAtPath:%@", path);
	
	// NOTE: If removeDirectoryAtPath is commented out, then this may be called
	// with a directory, in which case NSFileManager will recursively remove all
	// subdirectories. So be careful!
	
	for (id nodePath in [_manager nodePathsForPath:path error:error]) {
		[[NSFileManager defaultManager] removeItemAtPath:nodePath error:error];
	}
	
	return YES; // TODO: handle errors properly
}

#pragma mark Creating an Item

- (BOOL)createDirectoryAtPath:(NSString *)path 
                   attributes:(NSDictionary *)attributes
                        error:(NSError **)error {
	
	NSLog(@"createDirectoryAtPath:%@", path);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error createNew:YES];
	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	for (id nodePath in nodePaths) {
		[fileManager createDirectoryAtPath:nodePath withIntermediateDirectories:YES attributes:attributes error:error];
	}
	
	return YES; // TODO: handle errors properly
}

//TODO: Will not work with redundant path
- (BOOL)createFileAtPath:(NSString *)path
              attributes:(NSDictionary *)attributes
                userData:(id *)userData
                   error:(NSError **)error {
	
	NSLog(@"createFileAtPath: %@", path);
    
    NSString* fileName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    NSArray* nodePaths = nil;
    
    if(![[fileName substringToIndex:1] isEqualToString:@"."])
    {
        NSString *rootPath = [self chooseLocationModalForPath:path];
        
        if(rootPath != nil)
        {
            nodePaths = [_manager nodePathsForPath:path error:error firstOnly:YES createNew:YES forNodePaths:[NSArray arrayWithObject:rootPath] includePaths:YES];
        }
    }
	else
    {
        nodePaths = [_manager nodePathsForPath:path error:error createNew:YES];
    }
	
    if(nodePaths != nil)
    {
        for (id nodePath in nodePaths) {
            mode_t mode = [[attributes objectForKey:NSFilePosixPermissions] longValue];  
            int fd = creat([nodePath UTF8String], mode);
            if ( fd < 0 ) {
                *error = [NSError errorWithPOSIXCode:errno];
                NSLog(@"create failed");
                return NO;
            }
            *userData = [NSNumber numberWithLong:fd];
            NSLog(@"create succss");
            return YES;// Only first node...
        }
	}
    //We'll get here if we pressed cancel in the modal dialog
    *error = [NSError errorWithPOSIXCode:ECANCELED];
    return NO;
}

#pragma mark Linking an Item

- (BOOL)linkItemAtPath:(NSString *)path
                toPath:(NSString *)otherPath
                 error:(NSError **)error {
	
	NSLog(@"linkItemAtPath:%@ toPath:%@", path, otherPath);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error createNew:YES];
	NSArray* otherNodePaths = [_manager nodePathsForPath:otherPath error:error createNew:YES forNodePaths:nodePaths];
	
	int i;
	
	for (i = 0; i < [nodePaths count]; i++) {
		
		// We use link rather than the NSFileManager equivalent because it will copy
		// the file rather than hard link if part of the root path is a symlink.
		
		int rc = link([[nodePaths objectAtIndex:i] UTF8String], [[otherNodePaths objectAtIndex:i] UTF8String]);
		if ( rc <  0 ) {
			*error = [NSError errorWithPOSIXCode:errno];
			//return NO;
		}
		//return YES;
	}
	
	return YES; // TODO: handle errors properly
	
}

#pragma mark Symbolic Links

- (BOOL)createSymbolicLinkAtPath:(NSString *)path 
             withDestinationPath:(NSString *)otherPath
                           error:(NSError **)error {
	
	NSLog(@"createSymbolicLinkAtPath:%@ withDestinationPath:%@", path, otherPath);
	
	NSArray* sourceNodePaths = [_manager nodePathsForPath:path error:error];
	NSArray* destNodePaths = [_manager nodePathsForPath:otherPath error:error createNew:YES forNodePaths:sourceNodePaths];
	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	int i;
	for (i = 0; i < [sourceNodePaths count]; i++) {
		[fileManager createSymbolicLinkAtPath:[sourceNodePaths objectAtIndex:i] withDestinationPath:[destNodePaths objectAtIndex:i] error:error];
	}
	
	return YES; //TODO: handle errors properly  
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path
                                        error:(NSError **)error {
	
	NSLog(@"destinationOfSymbolicLinkAtPath:%@", path);
	return [[_manager nodePathsForPath:path error:error firstOnly:YES] objectAtIndex:0]; //TODO: ditch the array for firstOnly
}

#pragma mark File Contents

- (BOOL)openFileAtPath:(NSString *)path 
                  mode:(int)mode
              userData:(id *)userData
                 error:(NSError **)error {
	NSLog(@"openFileAtPath:%@ mode:%d", path, mode);
	NSString* p = [[_manager nodePathsForPath:path error:error firstOnly:YES] objectAtIndex:0]; //TODO: ditch the array for firstOnly
	int fd = open([p UTF8String], mode);
	if ( fd < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return NO;
	}
	*userData = [NSNumber numberWithLong:fd];
	return YES;
}

- (void)releaseFileAtPath:(NSString *)path userData:(id)userData {
	NSLog(@"releaseFileAtPath:%@",path);
	NSNumber* num = (NSNumber *)userData;
	int fd = [num longValue];
	close(fd);
}

- (int)readFileAtPath:(NSString *)path 
             userData:(id)userData
               buffer:(char *)buffer 
                 size:(size_t)size 
               offset:(off_t)offset
                error:(NSError **)error {
	
	NSLog(@"readFileAtPath:%@",path);
	
	NSNumber* num = (NSNumber *)userData;
	int fd = [num longValue];
	int ret = pread(fd, buffer, size, offset);
	if ( ret < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return -1;
	}
	return ret;
}

- (int)writeFileAtPath:(NSString *)path 
              userData:(id)userData
                buffer:(const char *)buffer
                  size:(size_t)size 
                offset:(off_t)offset
                 error:(NSError **)error {
	
	NSLog(@"writeFileAtPath:%@", path);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error createNew:YES];
	
	int ret;
	
	for (id nodePath in nodePaths) {
		NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:nodePath];
		
		int fd = [handle fileDescriptor];
		
		ret = pwrite(fd, buffer, size, offset);
		if ( ret < 0 ) {
			*error = [NSError errorWithPOSIXCode:errno];
			//return -1;
		}
		
	}
	
	return ret;
}

// TODO: need to fix this... needs thinking about
- (BOOL)exchangeDataOfItemAtPath:(NSString *)path1
                  withItemAtPath:(NSString *)path2
                           error:(NSError **)error {
	
	NSLog(@"exchangeDataOfItemAtPath:%@ withItemAtPath:%@ ***************************", path1, path2);
	
    //TODO: This will not work with redundant paths
	NSString* p1 = [[_manager nodePathsForPath:path1 error:error firstOnly:YES] objectAtIndex:0];
    NSString* p2 = [[_manager nodePathsForPath:path2 error:error firstOnly:YES] objectAtIndex:0];
    int ret = exchangedata([p1 UTF8String], [p2 UTF8String], 0);
    if ( ret < 0 ) {
        if ( error ) {
            *error = [NSError errorWithPOSIXCode:errno];
        }
        if(errno == EXDEV) //Cross-device link error. This means the file is at another drive
        {
            //TODO: This might be dangerous because there is a risk of data loss if it crashes midway. And I guess some metadata may get lost.
            [_manager createDirectoriesForNodePath:p2 error:error];
            NSLog(@"re %@ with %@",p2, p1);
            [[NSFileManager defaultManager] removeItemAtPath:p2 error:error];
            if(![[NSFileManager defaultManager] copyItemAtPath:p1 toPath:p2 error:error]) return NO;

        }
        else
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark Directory Contents

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
	
	NSLog(@"contentsOfDirectoryAtPath:%@", path);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error];
	
	NSMutableArray* arr = [[NSMutableArray alloc] init];
	
	for (id nodePath in nodePaths) {
		[arr addObjectsFromArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:nodePath error:error]];
	}
	
	// dedupe the result
    NSArray *result = [[NSSet setWithArray:arr] allObjects];
    //NSLog(@"result: %@",result);
	return result;
}

#pragma mark Getting and Setting Attributes

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error {
	//TODO: use something else than nsfilemanager to get all extended attributes.
    
	NSLog(@"attributesOfItemAtPath:%@",path);
	NSArray *allNodes = [_manager nodePathsForPath:path error:error];
	NSString* p = [allNodes objectAtIndex:0];
    //NSLog(@"attributesOfItemAtPath Node path: %@",p);
	NSDictionary* attribs = 
    [[NSFileManager defaultManager] attributesOfItemAtPath:p error:error];
    
    //Meanwhile we're adding the extended attributes by calling out extendedAttributesOfItemAtPath
    //NSLog(@"Attr: %@", attribs);
    NSMutableDictionary *attribsWithExtended = [attribs mutableCopy];
    NSArray *extendedAttribs = [self extendedAttributesOfItemAtPath:path error:error];
    
    if(extendedAttribs != nil && [extendedAttribs count] > 0)
    {
        //It seems like finder is okay with an array of extended attribs without the actual value.
        [attribsWithExtended setObject:extendedAttribs forKey:@"NSFileExtendedAttributes"];
        /*
        NSMutableDictionary *extendedAttribsWithValues = [[NSMutableDictionary alloc] init];
        for(NSString *attrib in extendedAttribs)
        {
            [extendedAttribsWithValues setObject:[self valueOfExtendedAttribute:attrib ofItemAtPath:path position:0 error:error] forKey:attrib];
        }
        [attribsWithExtended setObject:extendedAttribsWithValues forKey:@"NSFileExtendedAttributes"];
        */
        //NSLog(@"Attribs with extended attribs inserted: %@", attribsWithExtended);
        return attribsWithExtended;
    }
    else
    {
        return attribs;
    }
}

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path
                                          error:(NSError **)error {
	
	//NSLog(@"attributesOfFileSystemForPath:%@", path);
	NSString* p = [[_manager nodePathsForPath:path error:error firstOnly:YES] objectAtIndex:0];
    //NSLog(@"attributesOfFileSystemForPath Node path: %@",p);
	NSDictionary* d =
    [[NSFileManager defaultManager] attributesOfFileSystemForPath:p error:error];
	if (d) {
		NSMutableDictionary* attribs = [NSMutableDictionary dictionaryWithDictionary:d];
		[attribs setObject:[NSNumber numberWithBool:YES]
					forKey:kGMUserFileSystemVolumeSupportsExtendedDatesKey];
		return attribs;
	}
	return nil;
}

- (BOOL)setAttributes:(NSDictionary *)attributes 
         ofItemAtPath:(NSString *)path
             userData:(id)userData
                error:(NSError **)error {
	NSLog(@"setAttributes:%@ ofItemAtPath:%@",attributes,path);
	
	NSString* nodePath = [[_manager nodePathsForPath:path error:error firstOnly:YES] objectAtIndex:0];
	
		// TODO: Handle other keys not handled by NSFileManager setAttributes call.
		
    NSNumber* offset = [attributes objectForKey:NSFileSize];
    if ( offset ) {
        int ret = truncate([nodePath UTF8String], [offset longLongValue]);
        if ( ret < 0 ) {
            *error = [NSError errorWithPOSIXCode:errno];
            return NO;
        }
    }
    NSNumber* flags = [attributes objectForKey:kGMUserFileSystemFileFlagsKey];
    if (flags != nil) {
        int rc = chflags([nodePath UTF8String], [flags intValue]);
        if (rc < 0) {
            *error = [NSError errorWithPOSIXCode:errno];
            return NO;
        }
    }
    [[NSFileManager defaultManager] setAttributes:attributes
                                     ofItemAtPath:nodePath
                                            error:error];
		
	
	return YES; //TODO: handle errors properly
}

#pragma mark Extended Attributes

- (NSArray *)extendedAttributesOfItemAtPath:(NSString *)path error:(NSError **)error {
	NSLog(@"extendedAttributesOfItemAtPath:%@",path);
	
	NSString* p = [[_manager nodePathsForPath:path error:error firstOnly:YES] objectAtIndex:0];
	
	ssize_t size = listxattr([p UTF8String], nil, 0, 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}
	NSMutableData* data = [NSMutableData dataWithLength:size];
	size = listxattr([p UTF8String], [data mutableBytes], [data length], 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}
	NSMutableArray* contents = [NSMutableArray array];
	char* ptr = (char *)[data bytes];
	while ( ptr < ((char *)[data bytes] + size) ) {
		NSString* s = [NSString stringWithUTF8String:ptr];
		[contents addObject:s];
		ptr += ([s length] + 1);
	}
    
    //NSLog(@"contents: %@",contents);
	return contents;
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name 
                        ofItemAtPath:(NSString *)path
                            position:(off_t)position
                               error:(NSError **)error {  
	
	//NSLog(@"valueOfExtendedAttribute:%@ ofItemAtPath:%@",name,path);
    
	NSMutableData* data = nil;
    
    NSArray *allNodes =[_manager nodePathsForPath:path error:error];
    
	NSString* p = [allNodes objectAtIndex:0];
	
	ssize_t size = getxattr([p UTF8String], [name UTF8String], nil, 0,
							position, 0);
    
	if ( size < 0) { //failed to get attrib
		*error = [NSError errorWithPOSIXCode:errno];
	}
    else
    {
        data = [NSMutableData dataWithLength:size];
        size = getxattr([p UTF8String], [name UTF8String], 
                        [data mutableBytes], [data length],
                        position, 0);
        
        if ( size < 0 ) {
            *error = [NSError errorWithPOSIXCode:errno];
            data = nil;
        }
    }
    
    NSData *result = data;
    
    if([allNodes count] > 1)
    {
        //Tells finder the last tag was red
        
        if([name isEqualToString:@"com.apple.FinderInfo"])
        {
            if(data == nil)
            {
                data = [NSMutableData dataWithLength:32];
            }
            if(data != nil)
            {
                //NSLog(@"FinderInfo %@: %@",path,data);
                NSRange range = {9, 1};
                Byte replace = TAG_COLOR << 1;
                
                Byte check = 0x00;
                [data getBytes:&check range:range];
                if(check == 0x00)
                {
                    [data replaceBytesInRange:range withBytes:&replace];
                }
                
                //NSLog(@"ReplacInfo %@: %@",path,data);
            }
        }
        
        result = data;
        
        //Injects a tag called "Duplicate" into the metadata
        if([name isEqualToString:@"com.apple.metadata:_kMDItemUserTags"])
        {
            NSMutableArray *unserializedTags;
            NSPropertyListFormat format;
            if(data != nil)
            {
                NSString *error2;
                unserializedTags = [NSPropertyListSerialization propertyListFromData:data
                                                                    mutabilityOption:NSPropertyListMutableContainers
                                                                              format:&format
                                                                    errorDescription:&error2];
            }
            else
            {
                unserializedTags = [[NSMutableArray alloc] init];
                format = NSPropertyListBinaryFormat_v1_0;
            }
            if(unserializedTags != nil)
            {
                NSError **error2;
                
                [unserializedTags addObject:[NSString stringWithFormat:@"%@Location: %@",@TAG_PREFIX,[allNodes objectAtIndex:0]]];
                for(int i=1; i < [allNodes count]; i++)
                {
                    [unserializedTags addObject:[NSString stringWithFormat:@"%@Duplicate: %@\n%i",@TAG_PREFIX,[allNodes objectAtIndex:i],TAG_COLOR]];
                }
                //NSLog(@"tags: %@",unserializedTags);
                
                result = [NSPropertyListSerialization dataWithPropertyList:unserializedTags format:format options:0 error:error2];
            }
        }
        
    }

	return result;
}

- (BOOL)setExtendedAttribute:(NSString *)name 
                ofItemAtPath:(NSString *)path 
                       value:(NSData *)value
                    position:(off_t)position
					 options:(int)options
                       error:(NSError **)error {
	
	NSLog(@"setExtendedAttribute:%@ ofItemAtPath:%@",name,path);
    
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error firstOnly:YES];
    
    //Don't save the Grey tag, otherwise it will always do that when copying a duplicate file.
    //TODO: Should find a way to not needing to override a colored tag
    if([name isEqualToString:@"com.apple.FinderInfo"])
    {
        NSMutableData *mutableValue = [value mutableCopy];
        
        NSRange range = {9, 1};
        Byte check = 0x00;
        Byte replace = TAG_COLOR << 1;
        [mutableValue getBytes:&check range:range];
        replace = (check & ~replace);
        [mutableValue replaceBytesInRange:range withBytes:&replace];
        value = mutableValue;
    }
    //Don't save injected tags
    if([name isEqualToString:@"com.apple.metadata:_kMDItemUserTags"])
    {
        NSMutableArray *unserializedTags;
        NSPropertyListFormat format;
        if(value != nil)
        {
            NSString *error2;
            unserializedTags = [NSPropertyListSerialization propertyListFromData:value
                                                                mutabilityOption:NSPropertyListMutableContainers
                                                                          format:&format
                                                                errorDescription:&error2];
            
            for(NSString *tag in unserializedTags)
            {
                if([[tag substringToIndex:1] isEqualToString:@TAG_PREFIX])
                {
                    [unserializedTags removeObject:tag];
                }
                else if([[tag substringFromIndex:([tag length]-1)] isEqualToString:[NSString stringWithFormat:@"%i",TAG_COLOR]])
                {
                    [unserializedTags removeObject:tag];
                }
            }
            
            value = [NSPropertyListSerialization dataWithPropertyList:unserializedTags format:format options:0 error:nil];
        }
    }
    
	// Setting com.apple.FinderInfo happens in the kernel, so security related
	// bits are set in the options. We need to explicitly remove them or the call
	// to setxattr will fail.
	// TODO: Why is this necessary?
	
	options &= ~(XATTR_NOSECURITY | XATTR_NODEFAULT);
	
	for (id nodePath in nodePaths) {
		
		int ret = setxattr([nodePath UTF8String], [name UTF8String], 
						   [value bytes], [value length], 
						   position, options);
		if ( ret < 0 ) {
			*error = [NSError errorWithPOSIXCode:errno];
			return NO;
		}
	}
	
	
	return YES; //TODO: handle errors properly
}

- (BOOL)removeExtendedAttribute:(NSString *)name
                   ofItemAtPath:(NSString *)path
                          error:(NSError **)error {
	
	NSLog(@"removeExtendedAttribute:%@fItemAtPath:%@",name,path);
	
	NSArray* nodePaths = [_manager nodePathsForPath:path error:error];
	
	int ret;
	
	for (id nodePath in nodePaths) {
		
		ret = removexattr([nodePath UTF8String], [name UTF8String], 0);
		if ( ret < 0 ) {
			*error = [NSError errorWithPOSIXCode:errno];
			return NO;
		}
	}
	
	return YES; //TODO: handle errors properly
}


#pragma mark Services

- (void)moveToNode:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        
        NSString *path = [paths objectAtIndex:0];
        
        //TODO: Get this globally
        NSString *mountPath = @"/Volumes/PoolFS";
        
        if([[path substringToIndex:[mountPath length]] isEqualToString:mountPath])
        {
            NSError *errError;
            
            path = [path substringFromIndex:[mountPath length]];
            NSArray *sourceNodePaths = [_manager nodePathsForPath:path error:&errError firstOnly:YES];
            
            NSString *newNode = [self chooseLocationModalForPath:path];
            
            NSString *newPath = [newNode stringByAppendingString:path];
            NSString *newPathFolder = [newPath substringToIndex:([newPath length] - [[newPath lastPathComponent] length])];
            
            
            NSLog(@"Move %@ to %@",path,newPathFolder);
           
            [_manager createDirectoriesForNodePath:newPath error:&errError];
            if([[NSFileManager defaultManager] fileExistsAtPath:newPath] )
            {
                NSAlert *replaceAlert = [NSAlert alertWithMessageText:@"Warning"
                                defaultButton:@"Cancel"
                              alternateButton:@"Replace"
                                  otherButton:nil
                    informativeTextWithFormat:@"Do you want to replace %@ with %@?",newPath,[sourceNodePaths objectAtIndex:0]];
                if([replaceAlert runModal] == NSAlertDefaultReturn)
                {
                    return;
                }
            }
            
            NSString *appleScript = [NSString stringWithFormat:@"tell application \"Finder\"\n\
                                     move POSIX file \"%@\" to POSIX file \"%@\" with replacing\n\
                                     end tell\n\
                                     ",
                                     [sourceNodePaths objectAtIndex:0],newPathFolder ];
            
            NSLog(@"Running applescript: %@",appleScript);
            NSAppleScript *run = [[NSAppleScript alloc] initWithSource:appleScript];
            NSDictionary *errDict = nil;
            [run executeAndReturnError:&errDict];
            
            //We successfully moved the file but it was not removed from the source. (We copied between drives). Remove the source file
            if(errDict == nil && [[NSFileManager defaultManager] fileExistsAtPath:[sourceNodePaths objectAtIndex:0]] && [[NSFileManager defaultManager] fileExistsAtPath:newPath] )
            {
                [[NSFileManager defaultManager] removeItemAtPath:[sourceNodePaths objectAtIndex:0] error:&errError];
            }
        }
        else
        {
            
        }
    }
}

- (void)goToRealLocation:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        
        NSString *path = [paths objectAtIndex:0];
        
        //TODO: Get this globally
        NSString *mountPath = @"/Volumes/PoolFS";
        
        if([[path substringToIndex:[mountPath length]] isEqualToString:mountPath])
        {
            path = [path substringFromIndex:[mountPath length]];
            NSLog(@"Path: %@",path);
            NSError *errError;
            NSArray *nodePaths = [_manager nodePathsForPath:path error:&errError];
            
            if([nodePaths count] > 0)
            {
                for (NSString *nodePath in nodePaths) {
                    
                    if(nodePath != nil)
                    {
                        NSPasteboard *sendPboard = [NSPasteboard pasteboardWithUniqueName];
                        [sendPboard writeObjects:[NSArray arrayWithObject:nodePath]];
                        NSPerformService(@"Finder/Reveal", sendPboard);
                    }
                }
            }
        }
        else
        {
            NSPerformService(@"Finder/Reveal", pboard);
        }
    }
}

@end
