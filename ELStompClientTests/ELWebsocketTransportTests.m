//
//  ELWebsocketTransportTests.m
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ELWebsocketTransport.h"
#import "ELStompFrame.h"

@interface ELWebsocketTransportTests : XCTestCase

@property ELWebsocketTransport *transport;
@property id webSocketMock;

@end

@implementation ELWebsocketTransportTests

- (void)setUp {
  [super setUp];
  // Put setup code here; it will be run once, before the first test case.

  self.transport = [[ELWebsocketTransport alloc] init];
  self.webSocketMock = [OCMockObject mockForClass:[SRWebSocket class]];
}

- (void)tearDown {
  // Put teardown code here; it will be run once, after the last test case.
  [super tearDown];
}

- (void)testConnect {
  NSString *server = @"localhost";
  NSURL *url = [NSURL URLWithString:server];

  (void)[[[self.webSocketMock stub] andReturn:self.webSocketMock] initWithURL:url];
  [[self.webSocketMock expect] setDelegate:self.transport];
  [[self.webSocketMock expect] open];

  [[[[self.webSocketMock stub] classMethod] andReturn:self.webSocketMock] alloc];

  __block BOOL blockCalled = NO;
  [self.transport connectTo:server inBackground:^{
    blockCalled = YES;
  }];

  [self.transport webSocketDidOpen:self.webSocketMock];
  XCTAssertTrue(blockCalled, @"");
  XCTAssertTrue([self.transport isConnected], @"");

  [self.webSocketMock verify];
}

- (void)testDisconnect {
  [self testConnect];

  [[self.webSocketMock expect] close];

  [self.transport disconnect];

  XCTAssertFalse([self.transport isConnected], @"");
  [self.webSocketMock verify];
}

- (void)testSendWhenSocketOpen {
  [self testConnect];

  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"CONNECT" headers:nil body:nil];

  [[[self.webSocketMock stub] andReturnValue:@(SR_OPEN)] readyState];
  [[self.webSocketMock expect] send:[frame marshal]];

  [self.transport send:frame];

  [self.webSocketMock verify];
}

- (void)testSendWhenSocketClosed {
  [self testConnect];

  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"CONNECT" headers:nil body:nil];

  [[[self.webSocketMock stub] andReturnValue:@(SR_CLOSED)] readyState];

  [self.transport send:frame];

  [self.webSocketMock verify];
}

- (void)testReconnectsWhenClosedByError {
  [self testConnect];

  [[self.webSocketMock expect] setDelegate:nil];
  [[self.webSocketMock expect] setDelegate:self.transport];
  [[self.webSocketMock expect] open];

  [self.transport webSocket:self.webSocketMock didCloseWithCode:400 reason:@"Global thermonuclear war" wasClean:NO];

  [self.webSocketMock verify];
}

- (void)testDoesNotReconnectWhenClosedCleanly {
  [self testConnect];

  [self.transport webSocket:self.webSocketMock didCloseWithCode:-1 reason:nil wasClean:YES];

  [self.webSocketMock verify];
}

- (void)testReconnectsWhenFail {
  [self testConnect];

  [[self.webSocketMock expect] setDelegate:nil];
  [[self.webSocketMock expect] setDelegate:self.transport];
  [[self.webSocketMock expect] open];

  [self.transport webSocket:self.webSocketMock didFailWithError:[NSError errorWithDomain:@"Horror" code:456 userInfo:nil]];

  [self.webSocketMock verify];
}

@end
