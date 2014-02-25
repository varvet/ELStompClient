//
//  ELWebsocketTransport.h
//  ELStompClient
//
//  Created by Elabs Developer on 21/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>
#import "ELStompTransport.h"

@interface ELWebsocketTransport : NSObject <ELStompTransport, SRWebSocketDelegate>

@end
