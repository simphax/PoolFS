//
//  LocationSelectWindow.h
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LocationSelectWindow : NSWindowController

-(NSDictionary *) runModalWidthNodes:(NSArray *)nodes forPath:(NSString *)path;

@property (assign) IBOutlet NSButton *submitButton;

@property (strong, nonatomic) NSArray *nodePaths;

@property (assign) IBOutlet NSCollectionView *collectionView;

@property (assign) IBOutlet NSTextField *infoText;

@end
