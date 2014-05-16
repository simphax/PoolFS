//
//  LocationSelectWindow.m
//  PoolFS
//
//  Created by Simon on 2014-05-09.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import "LocationSelectWindow.h"
#import "NodeItem.h"

@interface LocationSelectWindow ()
{
    NSDictionary *_result;
}
@property (strong, nonatomic) NSTimer *timeoutTimer;
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
    [super awakeFromNib];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView setContent:_nodeItems];

        int index = 0;
        
        for(int i = 0; i<[_nodeItems count]; i++)
        {
            NodeItem *item = [_nodeItems objectAtIndex:i];
            if(item.latestUsed)
            {
                index = i;
                break;
            }
        }
        
        //Select the first row
        [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:index]];
        self.infoText.stringValue = [NSString stringWithFormat:@"Choose the node on which to place the file \"%@\"",[_path lastPathComponent]];
    
    
    
        //Timeout in 50 seconds
        //TODO: Set timeout as a setting? Or get it from somewhere. 60 seconds seems to be the OSXFUSE and Finder timeout.
    
        [self.window setContentMinSize:NSMakeSize(543, 200)];
        [self.window setContentMaxSize:NSMakeSize(543, 2000)];
        
        _timeoutTimer = [NSTimer timerWithTimeInterval: 50.0
                                                target: self
                                              selector: @selector(timeout:)
                                              userInfo: nil
                                               repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: _timeoutTimer
                                     forMode:NSModalPanelRunLoopMode];
    });
}


-(NSString *) windowNibName
{
    return @"LocationSelectWindow";
}

-(NSDictionary *) runModalWithNodeItems:(NSArray *)nodeItems forPath:(NSString *)path
{
    _nodeItems = nodeItems;
    
    _path = path;
    [self.window makeKeyAndOrderFront:self];
    
    
    [NSApp runModalForWindow:self.window];
    
    return _result;
}

- (IBAction)chooseSelectedAndClose:(id)sender
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
    
    NSIndexSet *selectedIndexes = [_collectionView selectionIndexes];
    NSInteger *selectedIndex = [selectedIndexes firstIndex];
    NSString *selectedNode = [[_nodeItems objectAtIndex:selectedIndex] nodePath];
    _result = [[NSDictionary alloc] initWithObjectsAndKeys:selectedNode,@"selectedNode", nil];
    
    [self close];
    [NSApp stopModal];
}

-(void) timeout:(NSTimer *) timer
{
    [self cancel];
}

-(void) cancel
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
    _result = nil;
    [self close];
    [NSApp stopModal];
}

- (IBAction)cancel:(id)sender
{
    [self cancel];
}

@end
