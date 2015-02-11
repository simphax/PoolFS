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
    _lastRootNode = 0;
	_nodes = [nodes retain];
	_redundantPaths = [redundantPaths retain];
	return self;
}

-(void)dealloc {
	[_nodes release];
	[_redundantPaths release];
	[super dealloc];
}

-(int) lastRootNode {
    return _lastRootNode;
}

-(NSArray*) availableRootNodes {
    NSMutableArray *available = [NSMutableArray array];
    for(NSString *node in _nodes)
    {
        NSError *error;
        NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:node error:&error];
        if(dirContent != nil) //Path exists.
        {
            [available addObject:node];
        }
    }
    return available;
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
                    _lastRootNode = i;
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
	
	
	if (createNew) {
        NSLog(@"Last root node is currently %i",_lastRootNode);
        if(sourceNodePaths != nil)
        {
            //TODO: Should we lookup all source nodes?
            
            //This will happen when moving a file.
            //We want to move the file at the same physical location
            // so we loop through the root nodes to see which one is the root for the source. Then use that.
            for(NSString *sourceNodePath in sourceNodePaths) {
                for(i = 0; i < [_nodes count]; i++)
                {
                    NSString *rootNode = [_nodes objectAtIndex:i];
                    if([[sourceNodePath substringToIndex:[rootNode length]] isEqualToString:rootNode])
                    {
                        _lastRootNode = i;
                        
                        [nodePaths addObject:[[[_nodes objectAtIndex:i] stringByAppendingString:path] retain]];
                        
                        break;
                    }
                }
            }
        } else {
            [nodePaths addObject:[[[_nodes objectAtIndex:_lastRootNode] stringByAppendingString:path] retain]];
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
