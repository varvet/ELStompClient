//
//  ELTCPTransport.m
//  ELStompClient
//
//  Created by Elabs Developer on 26/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ELTCPTransport.h"
#import "ELStompFrame.h"

#define FRAME_HEADER 10
#define FRAME_BODY 20

@interface ELTCPTransport ()

@property NSString *server;
@property uint16_t port;
@property GCDAsyncSocket *socket;

@property ELStompFrame *frame;

@property (nonatomic, strong) ELOnConnectBlock onConnectBlock;
@property (nonatomic, strong) ELOnMessageBlock onMessageBlock;

@end

@implementation ELTCPTransport

- (void)reconnect {
  NSError *error = nil;
  if(![self.socket connectToHost:self.server onPort:self.port error:&error]) {
    NSLog(@"Failed to connect: %@", error);
  }
}

- (void)readNextFrame {
  NSData *term = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
  [self.socket readDataToData:term withTimeout:-1 tag:FRAME_HEADER];
}

- (NSUInteger)parseFrameHeader:(NSData *)data {
  NSString *header = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  self.frame = [[ELStompFrame alloc] initWithMarshaledHeader:[header stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];

  if (self.frame.headers[@"content-length"]) {
    return [self.frame.headers[@"content-length"] intValue] + 1;
  } else {
    return -1;
  }
}

#pragma mark - ELStompTransport

- (void)setOnMessageBlock:(ELOnMessageBlock)block {
  _onMessageBlock = block;
}

- (void)connectTo:(NSString *)server inBackground:(void (^)(void))block {
  self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

  if ([server rangeOfString:@":"].location != NSNotFound) {
    NSArray *components = [server componentsSeparatedByString:@":"];
    self.server = components[0];
    self.port = [components[1] intValue];
  } else {
    self.server = server;
    self.port = 80;
  }

  self.onConnectBlock = block;

  NSError *error = nil;
  if(![self.socket connectToHost:self.server onPort:self.port error:&error]) {
    NSLog(@"Failed to connect: %@", error);
  }

  // See socket:didConnectToHost:port:
}

- (void)disconnect {
  self.server = nil;

  [self.socket disconnect];
  self.socket = nil;
}

- (BOOL)isConnected {
  return self.socket != nil;
}

- (void)send:(ELStompFrame *)frame {
  NSData *data = [[frame marshal] dataUsingEncoding:NSUTF8StringEncoding];
  [self.socket writeData:data withTimeout:-1 tag:0];
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
  self.onConnectBlock();
  [self readNextFrame];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  if (tag == FRAME_HEADER) {
    NSUInteger bodyLength = [self parseFrameHeader:data];

    if (bodyLength == -1) {
      NSData *term = [@"\0" dataUsingEncoding:NSUTF8StringEncoding];
      [self.socket readDataToData:term withTimeout:-1 tag:FRAME_BODY];
    } else {
      [self.socket readDataToLength:bodyLength withTimeout:-1 tag:FRAME_BODY];
    }
  } else if (tag == FRAME_BODY) {
    NSString *bodyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (self.frame.headers[@"content-length"]) {
      self.frame.body = [bodyString substringWithRange:NSMakeRange(0, [self.frame.headers[@"content-length"] intValue])];
    } else {
      self.frame.body = [bodyString substringWithRange:NSMakeRange(0, bodyString.length - 1)];
    }
    self.onMessageBlock(self.frame);

    [self readNextFrame];
  }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  if (err && self.server) {
    [self reconnect];
  }
}

@end
