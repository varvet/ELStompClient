//
//  ViewController.h
//  ExampleClient
//
//  Created by Elabs Developer on 25/02/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;

- (IBAction)sendMessage:(id)sender;

@end
