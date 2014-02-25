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
#import "ViewController.h"

@interface ViewController ()

@property ELStompClient *client;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  ELWebsocketTransport *websocketTransport = [[ELWebsocketTransport alloc] init];
  self.client = [[ELStompClient alloc] initWithTransport:websocketTransport];

  [self.client connectTo:@"ws://localhost:8675" inBackground:^{
    [self.client subscribeToDestination:@"test" withBlock:^(ELStompFrame *msg) {
      self.outputTextView.text = [self.outputTextView.text stringByAppendingString:msg.body];
    }];
  }];
}

- (IBAction)sendMessage:(id)sender {
  [self.client send:@"Hej hej!" toDestination:@"test"];
}

@end
