//
//  NodeItem.h
//  PoolFS
//
//  Created by Simon on 2014-05-13.
//  Copyright (c) 2014 Rubato. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NodeItem : NSObject

@property (strong, nonatomic) NSString *nodePath;
@property (nonatomic) BOOL latestUsed;
@property (nonatomic) long freeSpace;

@end
