//
//  ViewController.m
//  ExampleClient
//
//  Created by Elabs Developer on 25/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <ELStompClient/ELStompClient.h>
#import <ELStompClient/ELStompFrame.h>
#import <ELStompClient/ELWebsocketTransport.h>
#import <ELStompClient/ELTCPTransport.h>
#import "ViewController.h"

@interface ViewController ()

@property ELStompClient *client;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  //ELWebsocketTransport *websocketTransport = [[ELWebsocketTransport alloc] init];
  ELTCPTransport *tcpTransport = [[ELTCPTransport alloc] init];
  self.client = [[ELStompClient alloc] initWithTransport:tcpTransport];

  //NSString *address = @"ws://localhost:8675";
  NSString *address = @"localhost:8675";

  [self.client connectTo:address inBackground:^{
    [self.client subscribeToDestination:@"test" ackMode:@"client-individual" withBlock:^(ELStompFrame *msg) {
      self.outputTextView.text = [self.outputTextView.text stringByAppendingString:msg.body];
      [self.client send:[msg ackFrame]];
    }];
  }];
}

- (IBAction)sendMessage:(id)sender {
  [self.client send:@"Hej hej!" toDestination:@"test"];
}

@end
