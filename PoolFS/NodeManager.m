//
//  NodeManager.m
//  PoolFS
//
//  Created by Rory Sinclair on 26/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NodeManager.h"
#import "NSError+POSIX.h"


@implementation NodeManager

-(id) initWithNodes:(NSArray*)nodes andRedundantPaths:(NSArray*)redundantPaths {
    lastRootNode = 0;
	_nodes = [nodes retain];
	_redundantPaths = [redundantPaths retain];
	return self;
}

-(void)dealloc {
	[_nodes release];
	[_redundantPaths release];
	[super dealloc];
}

-(NSString*) nodeForPath:(NSString*)path error:(NSError **)error {
	return [[self nodePathsForPath:path error:error includePaths:NO] objectAtIndex:0];
}

-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error {
	return [self nodePathsForPath:path error:error firstOnly:NO createNew:NO forNodePaths:nil includePaths:YES];
}

-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error firstOnly:(BOOL)firstOnly {
	return [self nodePathsForPath:path error:error firstOnly:firstOnly createNew:NO forNodePaths:nil includePaths:YES];
}

-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error createNew:(BOOL)createNew {
	return [self nodePathsForPath:path error:error firstOnly:NO createNew:createNew forNodePaths:nil includePaths:YES];
}

-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error createNew:(BOOL)createNew forNodePaths:(NSArray*)nodePaths {
	return [self nodePathsForPath:path error:error firstOnly:NO createNew:createNew forNodePaths:nodePaths includePaths:YES];
}

-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error includePaths:(BOOL)includePaths {
	return [self nodePathsForPath:path error:error firstOnly:NO createNew:NO forNodePaths:nil includePaths:includePaths];
}

//TODO: forNodePaths isnt yet implemented - might break?
-(NSArray*) nodePathsForPath:(NSString*)path error:(NSError **)error firstOnly:(BOOL)firstOnly createNew:(BOOL)createNew forNodePaths:(NSArray*)sourceNodePaths includePaths:(BOOL)includePaths {
	
	NSMutableArray* nodePaths = [[NSMutableArray alloc] init];
	
    
	int i;

    /*if(sourceNodePaths != nil && firstOnly)
    {
        for (i = 0; i < [sourceNodePaths count]; i++) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[sourceNodePaths objectAtIndex:i]]) {
                lastRootNode = i;
                break;
            }
        }
        
        NSString* tempPath = [[[_nodes objectAtIndex:lastRootNode] stringByAppendingString:path] retain];
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:&isDir]) {
            if (includePaths) {
                [nodePaths addObject:tempPath];
            } else {
                [nodePaths addObject:[_nodes objectAtIndex:i]];
            }
        }
    }
    else
    {*/
        for (i = 0; i < [_nodes count]; i++) {
            NSString* tempPath = [[[_nodes objectAtIndex:i] stringByAppendingString:path] retain];
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:&isDir]) {
                
                if(!isDir)
                {
                    lastRootNode = i;
                }
                if (includePaths) {
                    [nodePaths addObject:tempPath];
                } else {
                    [nodePaths addObject:[_nodes objectAtIndex:i]];
                }

                if (firstOnly)
                    break;
            }
        }
    //}
	
	int minPaths = [self isRedundantPath:path] ? 2 : 1;
	
	while (createNew && [nodePaths count] < minPaths) {
        NSLog(@"Last root node is currently %i",lastRootNode);
        if(sourceNodePaths != nil)
        {
            //TODO: Should we lookup all source nodes?

            //This will happen when moving a file.
            //We want to move the file at the same physical location
            // so we loop through the root nodes to see which one is the root for the source. Then use that.
            NSString *sourceNodePath = [sourceNodePaths objectAtIndex:0];
            for(i = 0; i < [_nodes count]; i++)
            {
                NSString *rootNode = [_nodes objectAtIndex:i];
                if([[sourceNodePath substringToIndex:[rootNode length]] isEqualToString:rootNode])
                {
                    lastRootNode = i;
                    break;
                }
            }
        }
        int nodeIndex = lastRootNode; //TODO: Create new files on last queried root location. This is kinda unpredictable
        NSLog(@"Using last root node %i  for %@",nodeIndex,path);
        
		//int randomNode = random() % [_nodes count];
		//NSLog(@"randomly chose node %d in nodePathsForPath", randomNode);
		[nodePaths addObject:[[[_nodes objectAtIndex:nodeIndex] stringByAppendingString:path] retain]];
		
		// if this is a redundant path, select another (different) random node and add its path
        if ([self isRedundantPath:path]) {
			int previousNode = nodeIndex;
			
			while (nodeIndex == previousNode) {
				nodeIndex = random() % [_nodes count];
			}
		
			[nodePaths addObject:[[[_nodes objectAtIndex:nodeIndex] stringByAppendingString:path] retain]];
			
		}
		
		// finally create any intermediate directories we might need
		for (id nodePath in nodePaths) {
			[self createDirectoriesForNodePath:nodePath error:error];
		}
	}
	
	return nodePaths;
}

-(BOOL) createDirectoriesForNodePath:(NSString*)nodePath error:(NSError**)error {
	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* dir = [nodePath stringByDeletingLastPathComponent];
	
	if(![fileManager fileExistsAtPath:dir]) {
		[fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:error];
	}
	
	return YES;
	
}

//TODO: Not supported right now
-(BOOL) isRedundantPath:(NSString*)path {
    return NO;
	NSRange textRange;
	
	//NSLog(@"in isRedundantPath, checking path %@", path);
	
	for (NSString* redundantPath in _redundantPaths) {
		
		textRange =[path rangeOfString:redundantPath];
	
		if(textRange.location != NSNotFound)
		{
			NSLog(@"************************>>>>> redundant!");
			return YES;
		}
	}
	
	//NSLog(@"returning NO");

	return NO;
}

@end
