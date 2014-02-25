//
//  ELWebsocketTransport.m
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ELWebsocketTransport.h"
#import "ELStompFrame.h"

@interface ELWebsocketTransport ()

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *webSocketUrl;

@property (nonatomic, strong) ELOnConnectBlock onConnectBlock;
@property (nonatomic, strong) ELOnMessageBlock onMessageBlock;

@end

@implementation ELWebsocketTransport

- (void)reconnect {
  self.webSocket.delegate = nil;
  self.webSocket = nil;

  [self connectTo:self.webSocketUrl inBackground:self.onConnectBlock];
}

#pragma mark - ELStompTransport

- (void)setOnMessageBlock:(ELOnMessageBlock)block {
  _onMessageBlock = block;
}

- (void)connectTo:(NSString *)server inBackground:(void (^)(void))block {
  SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:server]];
  newWebSocket.delegate = self;

  self.webSocketUrl = server;

  self.onConnectBlock = block;

  [newWebSocket open];

  // See webSocketDidOpen:
}

- (void)disconnect {
  self.webSocketUrl = nil;

  [self.webSocket close];
  self.webSocket = nil;
}

- (BOOL)isConnected {
  return self.webSocket != nil;
}

- (void)send:(ELStompFrame *)frame {
  if (self.webSocket.readyState == SR_OPEN) {
    [self.webSocket send:[frame marshal]];
  }
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
  self.webSocket = webSocket;
  self.onConnectBlock();
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
  ELStompFrame *frame = [[ELStompFrame alloc] initWithMarshaledFrame:message];
  self.onMessageBlock(frame);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
  if (!(code == -1 && reason == nil) && self.webSocketUrl) {
    NSLog(@"WebSocket connection closed with code %d, reason %@. Reconnecting.", code, reason);
    [self reconnect];
  }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
  if (self.webSocketUrl) {
    NSLog(@"WebSocket failed with error %@. Reconnecting.", error);
    [self reconnect];
  }
}

@end
