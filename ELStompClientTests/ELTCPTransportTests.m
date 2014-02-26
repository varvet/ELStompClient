//
//  ELTCPTransportTests.m
//  ELStompClient
//
//  Created by Elabs Developer on 26/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ELTCPTransport.h"
#import "ELStompFrame.h"

@interface ELTCPTransportTests : XCTestCase

@property ELTCPTransport *transport;
@property id socketMock;

@end@implementation ELTCPTransportTests

- (void)setUp {
  [super setUp];
  // Put setup code here; it will be run once, before the first test case.

  self.transport = [[ELTCPTransport alloc] init];
  self.socketMock = [OCMockObject mockForClass:[GCDAsyncSocket class]];
}

- (void)tearDown {
  // Put teardown code here; it will be run once, after the last test case.
  [super tearDown];
}

- (void)testConnect {
  NSString *server = @"localhost:4567";

  (void)[[[self.socketMock stub] andReturn:self.socketMock] initWithDelegate:self.transport delegateQueue:dispatch_get_main_queue()];
  [[self.socketMock expect] connectToHost:@"localhost" onPort:4567 error:[OCMArg anyObjectRef]];
  [[self.socketMock expect] readDataToData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:10];

  [[[[self.socketMock stub] classMethod] andReturn:self.socketMock] alloc];

  __block BOOL blockCalled = NO;
  [self.transport connectTo:server inBackground:^{
    blockCalled = YES;
  }];

  [self.transport socket:self.socketMock didConnectToHost:@"127.0.0.1" port:4567];
  XCTAssertTrue(blockCalled, @"");
  XCTAssertTrue([self.transport isConnected], @"");

  [self.socketMock verify];
}

- (void)testDisconnect {
  [self testConnect];

  [[self.socketMock expect] disconnect];

  [self.transport disconnect];

  XCTAssertFalse([self.transport isConnected], @"");
  [self.socketMock verify];
}

- (void)testSend {
  [self testConnect];

  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"CONNECT" headers:nil body:nil];

  NSData *data = [frame.marshal dataUsingEncoding:NSUTF8StringEncoding];
  [[self.socketMock expect] writeData:data withTimeout:-1 tag:0];

  [self.transport send:frame];

  [self.socketMock verify];
}

- (void)testReconnectsWhenClosedByError {
  [self testConnect];

  [[self.socketMock expect] connectToHost:@"localhost" onPort:4567 error:[OCMArg anyObjectRef]];

  [self.transport socketDidDisconnect:self.socketMock withError:[NSError errorWithDomain:@"Horror" code:456 userInfo:nil]];

  [self.socketMock verify];
}

- (void)testDoesNotReconnectWhenClosedCleanly {
  [self testConnect];

  [self.transport socketDidDisconnect:self.socketMock withError:nil];

  [self.socketMock verify];
}

- (void)testReadsTheHeaderAndThenContentLengthBytes {
  (void)[[[self.socketMock stub] andReturn:self.socketMock] initWithDelegate:self.transport delegateQueue:dispatch_get_main_queue()];
  [[self.socketMock expect] connectToHost:@"localhost" onPort:80 error:[OCMArg anyObjectRef]];
  [[[[self.socketMock stub] classMethod] andReturn:self.socketMock] alloc];

  __block ELStompFrame *receivedFrame = nil;
  [self.transport setOnMessageBlock:^(ELStompFrame *frame) {
    receivedFrame = frame;
  }];

  NSData *headerData = [@"MESSAGE\nkey:value\ncontent-length:11\n\n" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *bodyData = [@"Hello\0Hello\0" dataUsingEncoding:NSUTF8StringEncoding];
  [[[self.socketMock expect] andDo:^(NSInvocation *invokation) {
    [self.transport socket:self.socketMock didReadData:headerData withTag:10];
  }] readDataToData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:10];
  [[[self.socketMock expect] andDo:^(NSInvocation *invokation) {
    [self.transport socket:self.socketMock didReadData:bodyData withTag:20];
  }] readDataToLength:12 withTimeout:-1 tag:20];
  [[self.socketMock expect] readDataToData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:10];

  [self.transport connectTo:@"localhost" inBackground:^{
  }];

  [self.transport socket:self.socketMock didConnectToHost:@"127.0.0.1" port:80];

  XCTAssertNotNil(receivedFrame, @"");
  XCTAssertEqualObjects(receivedFrame.command, @"MESSAGE", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"11", @"key": @"value"};
  XCTAssertEqualObjects(receivedFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(receivedFrame.body, @"Hello\0Hello", @"");
  [self.socketMock verify];
}

- (void)testReadsTheHeaderAndThenUntilNullChar {
  (void)[[[self.socketMock stub] andReturn:self.socketMock] initWithDelegate:self.transport delegateQueue:dispatch_get_main_queue()];
  [[self.socketMock expect] connectToHost:@"localhost" onPort:80 error:[OCMArg anyObjectRef]];
  [[[[self.socketMock stub] classMethod] andReturn:self.socketMock] alloc];

  __block ELStompFrame *receivedFrame = nil;
  [self.transport setOnMessageBlock:^(ELStompFrame *frame) {
    receivedFrame = frame;
  }];

  NSData *headerData = [@"MESSAGE\nkey:value\n\n" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *bodyData = [@"Hello hello\0" dataUsingEncoding:NSUTF8StringEncoding];
  [[[self.socketMock expect] andDo:^(NSInvocation *invokation) {
    [self.transport socket:self.socketMock didReadData:headerData withTag:10];
  }] readDataToData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:10];
  [[[self.socketMock expect] andDo:^(NSInvocation *invokation) {
    [self.transport socket:self.socketMock didReadData:bodyData withTag:20];
  }] readDataToData:[@"\0" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:20];
  [[self.socketMock expect] readDataToData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:10];

  [self.transport connectTo:@"localhost" inBackground:^{
  }];

  [self.transport socket:self.socketMock didConnectToHost:@"127.0.0.1" port:80];

  XCTAssertNotNil(receivedFrame, @"");
  XCTAssertEqualObjects(receivedFrame.command, @"MESSAGE", @"");
  NSDictionary *expectedHeaders = @{@"key": @"value"};
  XCTAssertEqualObjects(receivedFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(receivedFrame.body, @"Hello hello", @"");
  [self.socketMock verify];
}


@end
