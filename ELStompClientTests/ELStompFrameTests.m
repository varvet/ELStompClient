//
//  ELStompFrameTests.m
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ELStompFrame.h"

@interface ELStompFrameTests : XCTestCase

@property ELStompFrame *initializedFrame;

@end

@implementation ELStompFrameTests

- (void)setUp {
  [super setUp];
  // Put setup code here; it will be run once, before the first test case.
  self.initializedFrame = [[ELStompFrame alloc] initWithCommand:@"CONNECT" headers:@{@"key": @"value"} body:@"Hello"];
}

- (void)tearDown {
  // Put teardown code here; it will be run once, after the last test case.
  [super tearDown];
}

- (void)testInitialization {
  ELStompFrame *frame = self.initializedFrame;
  XCTAssertEqualObjects(frame.command, @"CONNECT", @"");
  XCTAssertEqualObjects(frame.headers, @{@"key": @"value"}, @"");
  XCTAssertEqualObjects(frame.body, @"Hello", @"");
}

- (void)testMarshaling {
  NSString *marshaledFrame = [self.initializedFrame marshal];
  XCTAssertEqualObjects(marshaledFrame, @"CONNECT\nkey:value\ncontent-length:5\n\nHello\0", @"");
}

- (void)testMarshalingWithEscapedHeaders {
  NSDictionary *headers = @{@"key\none": @"hello\reverybody", @"something:withcolon": @"something\\withbackspace"};
  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"SEND" headers:headers body:nil];
  NSString *marshaledFrame = [frame marshal];

  XCTAssertEqualObjects(marshaledFrame, @"SEND\nsomething\\cwithcolon:something\\\\withbackspace\nkey\\none:hello\\reverybody\n\n\0", @"");
}

- (void)testUnmarshaling {
  NSString *marshaledFrame = [self.initializedFrame marshal];
  ELStompFrame *unmarshaledFrame = [[ELStompFrame alloc] initWithMarshaledFrame:marshaledFrame];
  XCTAssertEqualObjects(unmarshaledFrame.command, @"CONNECT", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"5", @"key": @"value"};
  XCTAssertEqualObjects(unmarshaledFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(unmarshaledFrame.body, @"Hello", @"");
}

- (void)testUnmarshalingWithEncodedHeaders {
  ELStompFrame *frame = [[ELStompFrame alloc] initWithMarshaledFrame:@"SEND\nsomething\\cwithcolon:something\\\\withbackspace\nkey\\none:hello\\reverybody\n\n\0"];

  XCTAssertEqualObjects(frame.command, @"SEND", @"");
  NSDictionary *expectedHeaders = @{@"key\none": @"hello\reverybody", @"something:withcolon": @"something\\withbackspace"};
  XCTAssertEqualObjects(frame.headers, expectedHeaders, @"");
}

- (void)testUnmarshalingWithCRLF {
  NSString *marshaledFrame = @"CONNECT\r\nkey:value\r\ncontent-length:5\r\n\r\nHello\0";

  ELStompFrame *unmarshaledFrame = [[ELStompFrame alloc] initWithMarshaledFrame:marshaledFrame];
  XCTAssertEqualObjects(unmarshaledFrame.command, @"CONNECT", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"5", @"key": @"value"};
  XCTAssertEqualObjects(unmarshaledFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(unmarshaledFrame.body, @"Hello", @"");
}

- (void)testUnmarshalingWithExtraEOLs {
  NSString *marshaledFrame = @"CONNECT\nkey:value\ncontent-length:5\n\nHello\0\n\n\n";

  ELStompFrame *unmarshaledFrame = [[ELStompFrame alloc] initWithMarshaledFrame:marshaledFrame];
  XCTAssertEqualObjects(unmarshaledFrame.command, @"CONNECT", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"5", @"key": @"value"};
  XCTAssertEqualObjects(unmarshaledFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(unmarshaledFrame.body, @"Hello", @"");
}

- (void)testUnmarshalingWithRepeatedHeaders {
  NSString *marshaledFrame = @"CONNECT\nkey:value\nkey:oldvalue\ncontent-length:5\n\nHello\0\n\n\n";

  ELStompFrame *unmarshaledFrame = [[ELStompFrame alloc] initWithMarshaledFrame:marshaledFrame];
  XCTAssertEqualObjects(unmarshaledFrame.command, @"CONNECT", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"5", @"key": @"value"};
  XCTAssertEqualObjects(unmarshaledFrame.headers, expectedHeaders, @"");
  XCTAssertEqualObjects(unmarshaledFrame.body, @"Hello", @"");
}

- (void)testWithNullInBody {
  ELStompFrame *frame = [[ELStompFrame alloc] initWithCommand:@"SEND" headers:nil body:@"Hello\0null\0chars"];
  XCTAssertEqualObjects(frame.body, @"Hello\0null\0chars", @"");

  NSString *marshaledFrame = [frame marshal];
  XCTAssertEqualObjects(marshaledFrame, @"SEND\ncontent-length:16\n\nHello\0null\0chars\0", @"");

  frame = [[ELStompFrame alloc] initWithMarshaledFrame:marshaledFrame];
  XCTAssertEqualObjects(frame.headers[@"content-length"], @"16", @"");
  XCTAssertEqualObjects(frame.body, @"Hello\0null\0chars", @"");
}

- (void)testUnmarshalingHeadersOnly {
  NSString *marshaledHeader = @"CONNECT\nkey:value\ncontent-length:5";

  ELStompFrame *unmarshaledFrame = [[ELStompFrame alloc] initWithMarshaledHeader:marshaledHeader];
  XCTAssertEqualObjects(unmarshaledFrame.command, @"CONNECT", @"");
  NSDictionary *expectedHeaders = @{@"content-length": @"5", @"key": @"value"};
  XCTAssertEqualObjects(unmarshaledFrame.headers, expectedHeaders, @"");
  XCTAssertNil(unmarshaledFrame.body, @"");
}

@end
