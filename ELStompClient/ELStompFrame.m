//
//  ELStompFrame.m
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ELStompFrame.h"

@implementation ELStompFrame

- (id)initWithCommand:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body {
  if (self = [super init]) {
    self.command = command;
    self.headers = headers;
    self.body = body;
  }

  return self;
}

- (id)initWithMarshaledFrame:(NSString *)frame {
  NSArray *components = [frame componentsSeparatedByString:@"\n\n"];
  if ([components count] < 2) {
    components = [frame componentsSeparatedByString:@"\r\n\r\n"];
  }

  if (self = [self initWithMarshaledHeader:components[0]]) {
    NSString *bodyData = components[1];

    if (self.headers[@"content-length"]) {
      self.body = [bodyData substringToIndex:[self.headers[@"content-length"] intValue]];
    } else {
      NSRange endRange = [bodyData rangeOfString:@"\0"];
      self.body = [bodyData substringToIndex:endRange.location];
    }
  }

  return self;
}

- (id)initWithMarshaledHeader:(NSString *)header {
  if (self = [super init]) {
    NSMutableArray *headerLines = [[header componentsSeparatedByString:@"\n"] mutableCopy];

    self.command = [headerLines[0] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    [headerLines removeObjectAtIndex:0];

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    for (NSString *headerLine in [headerLines reverseObjectEnumerator]) {
      NSString *trimmedHeaderLine = [headerLine stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
      NSArray *headerComponents = [trimmedHeaderLine componentsSeparatedByString:@":"];
      mutableHeaders[[self decodeHeader:headerComponents[0]]] = [self decodeHeader:headerComponents[1]];
    }

    self.headers = [NSDictionary dictionaryWithDictionary:mutableHeaders];
  }

  return self;
}

- (NSString *)marshal {
  NSMutableString *frame = [[NSMutableString alloc] init];

  [frame appendFormat:@"%@\n", self.command];
  for (NSString *key in [self.headers allKeys]) {
    [frame appendFormat:@"%@:%@\n", [self encodeHeader:key], [self encodeHeader:self.headers[key]]];
  }
  if (self.body) {
    [frame appendFormat:@"content-length:%lu\n", (unsigned long)[self.body length]];
  }
  [frame appendString:@"\n"];
  if (self.body) {
    [frame appendString:self.body];
  }
  [frame appendString:@"\0"];

  return [NSString stringWithString:frame];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ - %@ - %@", self.command, self.headers, self.body];
}

- (NSString *)encodeHeader:(NSString *)header {
  NSMutableString *string = [header mutableCopy];
  [string replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@":" withString:@"\\c" options:0 range:NSMakeRange(0, string.length)];
  return string;
}

- (NSString *)decodeHeader:(NSString *)header {
  NSMutableString *string = [header mutableCopy];
  [string replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@"\\r" withString:@"\r" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, string.length)];
  [string replaceOccurrencesOfString:@"\\c" withString:@":" options:0 range:NSMakeRange(0, string.length)];
  return string;
}

@end
