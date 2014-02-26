//
//  ELStompFrame.h
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ELStompFrame : NSObject

@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSString *body;

- (id)initWithCommand:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body;
- (id)initWithMarshaledFrame:(NSString *)frame;
- (id)initWithMarshaledHeader:(NSString *)header;
- (NSString *)marshal;

- (ELStompFrame *)ackFrame;
- (ELStompFrame *)nackFrame;

@end
