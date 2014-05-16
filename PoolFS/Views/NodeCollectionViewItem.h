//
//  NodeCollectionViewItem.h
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NodeItem.h"

@interface NodeCollectionViewItem : NSCollectionViewItem

@property (strong,nonatomic) NodeItem *nodeItem;

@property (assign,atomic) IBOutlet NSButton *latestLabel;
@property (assign,atomic) IBOutlet NSButton *freeSpaceLabel;

@end
