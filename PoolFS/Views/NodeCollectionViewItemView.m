//
//  NodeCollectionViewItemView.m
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import "NodeCollectionViewItemView.h"

@implementation NodeCollectionViewItemView

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
    if (self.selected) {
        [[NSColor alternateSelectedControlColor] set];
        NSRect rect = [self bounds];
        
        int margin = 5;
        rect.origin.x += margin;
        rect.origin.y += margin;
        rect.size.height -= margin*2;
        rect.size.width -= margin*2;
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
        [path fill];
    }
}

@end
