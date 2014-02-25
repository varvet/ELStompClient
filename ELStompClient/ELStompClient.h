//
//  ELStompClient.h
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ELStompTransport.h"

@class ELStompFrame;

typedef void(^ELSubscriptionCallback)(ELStompFrame *msg);

@interface ELStompClient : NSObject

@property (readonly) NSString *versionUsed;
@property (readonly) NSString *sessionId;
@property (readonly) NSString *serverInfo;

- (id)initWithTransport:(id <ELStompTransport>)transport;
- (Class)transportClass;

- (void)connectTo:(NSString *)server inBackground:(ELOnConnectBlock)block;
- (void)disconnect;
- (BOOL)isConnected;

- (NSString *)subscribeToDestination:(NSString *)destination withBlock:(ELSubscriptionCallback)block;
- (void)unsubscribe:(NSString *)subscriptionId;

- (void)send:(NSString *)body toDestination:(NSString *)destination;

@end
