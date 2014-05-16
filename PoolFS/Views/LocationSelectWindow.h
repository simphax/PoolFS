//
//  LocationSelectWindow.h
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NodeCollectionView.h"

@interface LocationSelectWindow : NSWindowController

-(NSDictionary *) runModalWithNodeItems:(NSArray *)nodeItems forPath:(NSString *)path;

@property (assign) IBOutlet NSButton *submitButton;

@property (strong, nonatomic) NSArray *nodeItems;

@property (assign) IBOutlet NodeCollectionView *collectionView;

@property (assign) IBOutlet NSTextField *infoText;

- (IBAction)cancel:(id)sender;

@end
