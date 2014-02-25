//
//  ELStompClientTests.m
//  ELStompClientTests
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ELStompClient.h"
#import "ELStompTransport.h"
#import "ELStompFrame.h"

@interface ELStompClientTests : XCTestCase

@property id transportMock;
@property ELStompClient *client;

@end

@implementation ELStompClientTests

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testInitalization {
  ELStompClient *client = [[ELStompClient alloc] initWithTransport:nil];
  XCTAssertNotNil(client, @"");
  XCTAssertNil(client.transportClass, @"");
}

- (void)testConnecting {
  self.transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  __block ELOnMessageBlock onMessageBlock;
  [[self.transportMock expect] setOnMessageBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
    onMessageBlock = obj;
    return YES;
  }]];

  __block ELOnConnectBlock onConnectBlock;
  [[self.transportMock expect] connectTo:@"localhost" inBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
    onConnectBlock = obj;
    return YES;
  }]];

  [[self.transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    return [((ELStompFrame *)obj).command isEqualToString:@"CONNECT"];
  }]];

  self.client = [[ELStompClient alloc] initWithTransport:self.transportMock];
  [self.client connectTo:@"localhost"];

  onConnectBlock();

  NSDictionary *connectedHeaders = @{@"version": @"1.2", @"session": @"s1", @"server": @"MockServer/1.0"};
  ELStompFrame *connectedFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECTED" headers:connectedHeaders body:nil];
  onMessageBlock(connectedFrame);

  XCTAssertEqualObjects(self.client.versionUsed, @"1.2", @"");
  XCTAssertEqualObjects(self.client.sessionId, @"s1", @"");
  XCTAssertEqualObjects(self.client.serverInfo, @"MockServer/1.0", @"");

  [self.transportMock verify];
}

- (void)testSubscribe {
  [self testConnecting];

  [[self.transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    return [((ELStompFrame *)obj).command isEqualToString:@"SUBSCRIBE"];
  }]];

  NSString *subscribeId = [self.client subscribeToDestination:@"topic1" withBlock:^(ELStompFrame *msg) {
  }];

  XCTAssertNotNil(subscribeId, @"");
  [self.transportMock verify];
}

- (void)testSubscribeWithNilBlock {
  ELStompClient *client = [[ELStompClient alloc] initWithTransport:nil];
  XCTAssertThrows([client subscribeToDestination:@"topic1" withBlock:nil], @"");
}

- (void)testUnsubscribe {
  id transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  [[transportMock expect] setOnMessageBlock:[OCMArg any]];
  ELStompClient *client = [[ELStompClient alloc] initWithTransport:transportMock];

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"UNSUBSCRIBE"] && [frame.headers[@"id"] isEqualToString:@"sub-1"];
  }]];

  [client unsubscribe:@"sub-1"];

  [transportMock verify];
}

- (void)testReceivingDataOnSubscription {
  self.transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  __block ELOnMessageBlock onMessageBlock;
  [[self.transportMock expect] setOnMessageBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
    onMessageBlock = obj;
    return YES;
  }]];

  __block ELOnConnectBlock onConnectBlock;
  [[self.transportMock expect] connectTo:@"localhost" inBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
    onConnectBlock = obj;
    return YES;
  }]];

  [[self.transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    return [((ELStompFrame *)obj).command isEqualToString:@"CONNECT"];
  }]];

  self.client = [[ELStompClient alloc] initWithTransport:self.transportMock];
  [self.client connectTo:@"localhost"];

  onConnectBlock();

  NSDictionary *connectedHeaders = @{@"version": @"1.2", @"session": @"s1", @"server": @"MockServer/1.0"};
  ELStompFrame *connectedFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECTED" headers:connectedHeaders body:nil];
  onMessageBlock(connectedFrame);

  [[self.transportMock stub] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    return [((ELStompFrame *)obj).command isEqualToString:@"SUBSCRIBE"];
  }]];

  __block BOOL topic1CallbackCalled = NO;
  NSString *topic1SubId = [self.client subscribeToDestination:@"topic1" withBlock:^(ELStompFrame *msg) {
    topic1CallbackCalled = YES;
  }];

  __block BOOL topic2CallbackCalled = NO;
  NSString *topic2SubId = [self.client subscribeToDestination:@"topic2" withBlock:^(ELStompFrame *msg) {
    topic2CallbackCalled = YES;
  }];

  ELStompFrame *topic1Frame = [[ELStompFrame alloc] initWithCommand:@"MESSAGE" headers:@{@"subscription": topic1SubId} body:@"Hello"];
  onMessageBlock(topic1Frame);
  XCTAssertTrue(topic1CallbackCalled, @"");

  ELStompFrame *topic2Frame = [[ELStompFrame alloc] initWithCommand:@"MESSAGE" headers:@{@"subscription": topic2SubId} body:@"Hello"];
  onMessageBlock(topic2Frame);
  XCTAssertTrue(topic2CallbackCalled, @"");

  [self.transportMock verify];
}

- (void)testSendingFrame {
  id transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  [[transportMock expect] setOnMessageBlock:[OCMArg any]];
  ELStompClient *client = [[ELStompClient alloc] initWithTransport:transportMock];

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"SEND"] && [frame.headers[@"destination"] isEqualToString:@"dest1"] && [frame.body isEqualToString:@"Message"];
  }]];

  [client send:@"Message" toDestination:@"dest1"];

  [transportMock verify];
}

- (void)testResubscribesToSubscriptionsIfReconnectingDueToError {
  id transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  __block ELOnMessageBlock onMessageBlock;
  [[transportMock expect] setOnMessageBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
    onMessageBlock = obj;
    return YES;
  }]];

  ELStompClient *client = [[ELStompClient alloc] initWithTransport:transportMock];

  __block ELOnConnectBlock onConnectBlock;
  [[transportMock stub] connectTo:@"localhost" inBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
    onConnectBlock = obj;
    return YES;
  }]];

  [[transportMock stub] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"CONNECT"];
  }]];

  [client connectTo:@"localhost"];
  onConnectBlock();

  NSDictionary *connectedHeaders = @{@"version": @"1.2", @"session": @"s1", @"server": @"MockServer/1.0"};
  ELStompFrame *connectedFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECTED" headers:connectedHeaders body:nil];
  onMessageBlock(connectedFrame);

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"SUBSCRIBE"];
  }]];

  [client subscribeToDestination:@"topic-1" withBlock:^(ELStompFrame *msg) {
  }];

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"SUBSCRIBE"];
  }]];

  onConnectBlock();
  onMessageBlock(connectedFrame);

  [transportMock verify];
}

- (void)testDoesNotResubscribeToSubscriptionsIfManuallyReconnecting {
  id transportMock = [OCMockObject mockForProtocol:@protocol(ELStompTransport)];

  __block ELOnMessageBlock onMessageBlock;
  [[transportMock expect] setOnMessageBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
    onMessageBlock = obj;
    return YES;
  }]];

  ELStompClient *client = [[ELStompClient alloc] initWithTransport:transportMock];

  __block ELOnConnectBlock onConnectBlock;
  [[transportMock stub] connectTo:@"localhost" inBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
    onConnectBlock = obj;
    return YES;
  }]];

  [[transportMock stub] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"CONNECT"];
  }]];

  [client connectTo:@"localhost"];
  onConnectBlock();

  NSDictionary *connectedHeaders = @{@"version": @"1.2", @"session": @"s1", @"server": @"MockServer/1.0"};
  ELStompFrame *connectedFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECTED" headers:connectedHeaders body:nil];
  onMessageBlock(connectedFrame);

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"SUBSCRIBE"];
  }]];

  [client subscribeToDestination:@"topic-1" withBlock:^(ELStompFrame *msg) {
  }];

  [[transportMock expect] send:[OCMArg checkWithBlock:^BOOL(id obj) {
    ELStompFrame *frame = obj;
    return [frame.command isEqualToString:@"DISCONNECT"];
  }]];

  [[transportMock expect] disconnect];

  [client disconnect];

  [client connectTo:@"localhost"];
  onConnectBlock();
  onMessageBlock(connectedFrame);

  [transportMock verify];
}

@end
