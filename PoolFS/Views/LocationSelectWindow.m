//
//  LocationSelectWindow.m
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import "LocationSelectWindow.h"

@interface LocationSelectWindow ()
{
    NSDictionary *_result;
}

@property (strong, nonatomic) NSString *path;

@end

@implementation LocationSelectWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib{
    [_collectionView setContent:_nodePaths];
    //Select the first row
    [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
    self.infoText.stringValue = [NSString stringWithFormat:@"Choose the node on which to place the file \"%@\"",[_path lastPathComponent]];
}

-(NSString *) windowNibName
{
    return @"LocationSelectWindow";
}

-(NSDictionary *) runModalWidthNodes:(NSArray *)nodes forPath:(NSString *)path
{
    _nodePaths = nodes;
    _path = path;
    [self.window makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:self.window];
    
    return _result;
}

- (IBAction)chooseSelectedAndClose:(id)sender {
    
    NSIndexSet *selectedIndexes = [_collectionView selectionIndexes];
    NSNumber *selectedIndex = [NSNumber numberWithInteger:[selectedIndexes firstIndex]];
    _result = [[NSDictionary alloc] initWithObjectsAndKeys:selectedIndex,@"selectedIndex", nil];
    
    [self close];
    [NSApp stopModal];
}

- (IBAction)cancel:(id)sender {
    _result = nil;
    [self close];
    [NSApp stopModal];
}

@end
