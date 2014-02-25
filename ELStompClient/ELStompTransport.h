//
//  ELStompTransport.h
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ELStompFrame;

typedef void(^ELOnConnectBlock)(void);
typedef void(^ELOnMessageBlock)(ELStompFrame *frame);

@protocol ELStompTransport <NSObject>

- (void)setOnMessageBlock:(ELOnMessageBlock)block;

- (void)connectTo:(NSString *)server inBackground:(ELOnConnectBlock)block;
- (void)disconnect;
- (BOOL)isConnected;

- (void)send:(ELStompFrame *)frame;

@end
