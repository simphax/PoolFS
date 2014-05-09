//
//  NodeCollectionView.m
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import "NodeCollectionView.h"

@implementation NodeCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object
{
    NSCollectionViewItem *item =[super newItemForRepresentedObject:object];
    
    [item.textField setStringValue:[NSString stringWithFormat:@"%@",object]];
    
    return item;
}

- (void)keyDown:(NSEvent *)theEvent
{
    //Pass return key event to window
    if([theEvent keyCode] == 36 || [theEvent keyCode] == 49)
    {
        [self.window keyDown:theEvent];
    }
    else
    {
        [super keyDown:theEvent];
    }
}

@end
