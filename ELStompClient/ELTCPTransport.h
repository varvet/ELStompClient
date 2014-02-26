//
//  ELTCPTransport.h
//  ELStompClient
//
//  Created by Elabs Developer on 26/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "ELStompTransport.h"

@interface ELTCPTransport : NSObject <ELStompTransport, GCDAsyncSocketDelegate>

@end
