//
//  NodeCollectionViewItem.m
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import "NodeCollectionViewItem.h"
#import "NodeCollectionViewItemView.h"

@interface NodeCollectionViewItem ()

@end

@implementation NodeCollectionViewItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    if([self representedObject] != nil)
    {
        NodeItem *nodeItem = (NodeItem*)representedObject;
        
        [[self textField] setStringValue:nodeItem.nodePath];
        [[self latestLabel] setHidden:!nodeItem.latestUsed];
        
        double freeGB = (double)nodeItem.freeSpace / 1000.0 / 1000.0 / 1000.0;
        
        [[self freeSpaceLabel] setTitle:[NSString stringWithFormat:@"%.02f GB free",freeGB]];
    }
}

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    NSColor *textColor = flag ?[NSColor whiteColor] : [NSColor blackColor];
    [self.textField setTextColor:textColor];
    [(NodeCollectionViewItemView*)[self view] setSelected:flag];
    [(NodeCollectionViewItemView*)[self view] setNeedsDisplay:YES];
}

@end
