//
//  ELStompClient.m
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ELStompClient.h"
#import "ELStompFrame.h"

@interface ELStompClient ()

@property NSString *versionUsed;
@property NSString *sessionId;
@property NSString *serverInfo;

@property (nonatomic, strong) id <ELStompTransport> transport;
@property (nonatomic, strong) NSMutableDictionary *subscriptions;

@property (nonatomic, strong) ELOnConnectBlock onConnectBlock;

@end

@implementation ELStompClient

#pragma mark - Lifecycle

- (id)initWithTransport:(id<ELStompTransport>)transport {
  if (self = [super init]) {
    self.transport = transport;
    [transport setOnMessageBlock:^(ELStompFrame *frame) {
      [self receive:frame];
    }];

    self.subscriptions = [NSMutableDictionary dictionary];
  }

  return self;
}

- (Class)transportClass {
  return [self.transport class];
}


#pragma mark - Connection

- (void)connectTo:(NSString *)server inBackground:(ELOnConnectBlock)block {
  self.onConnectBlock = block;
  [self.transport connectTo:server inBackground:^{
    NSDictionary *headers = @{@"accept-version": @"1.2", @"host": server};
    ELStompFrame *connectFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECT" headers:headers body:nil];
    [self.transport send:connectFrame];
  }];
}

- (void)disconnect {
  self.subscriptions = [NSMutableDictionary dictionary];

  ELStompFrame *disconnectFrame = [[ELStompFrame alloc] initWithCommand:@"DISCONNECT" headers:nil body:nil];
  [self.transport send:disconnectFrame];

  [self.transport disconnect];
}

- (BOOL)isConnected {
  return [self.transport isConnected];
}


#pragma mark - Subscriptions

- (NSString *)subscribeToDestination:(NSString *)destination withBlock:(ELSubscriptionCallback)block {
  return [self subscribeToDestination:destination ackMode:@"auto" withBlock:block];
}

- (NSString *)subscribeToDestination:(NSString *)destination withBlock:(ELSubscriptionCallback)block useId:(NSString *)subscriptionId {
  return [self subscribeToDestination:destination ackMode:@"auto" withBlock:block useId:subscriptionId];
}

- (NSString *)subscribeToDestination:(NSString *)destination ackMode:(NSString *)ackMode withBlock:(ELSubscriptionCallback)block {
  static NSInteger counter = 0;
  NSString *subscriptionId = [NSString stringWithFormat:@"sub-%d", counter++];

  return [self subscribeToDestination:destination ackMode:ackMode withBlock:block useId:subscriptionId];
}

- (NSString *)subscribeToDestination:(NSString *)destination ackMode:(NSString *)ackMode withBlock:(ELSubscriptionCallback)block useId:(NSString *)subscriptionId {
  NSAssert(block != nil, @"Message handler block must not be nil");

  NSMutableDictionary *headers = [@{@"destination": destination, @"id": subscriptionId} mutableCopy];
  if (ackMode && ![ackMode isEqualToString:@"auto"]) {
    headers[@"ack"] = ackMode;
  }
  ELStompFrame *subscribeFrame = [[ELStompFrame alloc] initWithCommand:@"SUBSCRIBE" headers:headers body:nil];

  NSDictionary *subscriptionData = @{ @"headers": headers, @"callback": [block copy] };
  [self.subscriptions setObject:subscriptionData forKey:subscriptionId];

  [self.transport send:subscribeFrame];

  return subscriptionId;
}

- (void)unsubscribe:(NSString *)subscriptionId {
  if (subscriptionId == nil) {
    return;
  }

  NSDictionary *headers = @{@"id": subscriptionId};
  ELStompFrame *unsubscribeFrame = [[ELStompFrame alloc] initWithCommand:@"UNSUBSCRIBE" headers:headers body:nil];

  [self.transport send:unsubscribeFrame];

  [self.subscriptions removeObjectForKey:subscriptionId];
}


#pragma mark - Sending data

- (void)send:(NSString *)body toDestination:(NSString *)destination {
  NSDictionary *headers = @{@"destination": destination};
  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"SEND" headers:headers body:body];
  [self.transport send:frame];
}

- (void)send:(ELStompFrame *)frame {
  [self.transport send:frame];
}


#pragma mark - Receiving data

- (void)receive:(ELStompFrame *)frame {
  if (frame.headers[@"subscription"]) {
    NSDictionary *subscriptionData = self.subscriptions[frame.headers[@"subscription"]];
    ELSubscriptionCallback block = subscriptionData[@"callback"];
    if (block) {
      block(frame);
    }
    return;
  }

  if ([frame.command isEqualToString:@"CONNECTED"]) {
    self.versionUsed = frame.headers[@"version"];
    self.sessionId = frame.headers[@"session"];
    self.serverInfo = frame.headers[@"server"];

    // Resubscribe all subscriptions if we reconnected due to connection failure
    for (NSString *subscriptionId in [self.subscriptions allKeys]) {
      NSDictionary *subscriptionData = self.subscriptions[subscriptionId];
      NSDictionary *headers = subscriptionData[@"headers"];
      [self subscribeToDestination:headers[@"destination"] ackMode:headers[@"ack"] withBlock:subscriptionData[@"callback"] useId:subscriptionId];
    }

    if (self.onConnectBlock) {
      self.onConnectBlock();
    }
    return;
  }
}

@end
