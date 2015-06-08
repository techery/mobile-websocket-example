//
//  ViewController.m
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ViewController.h"
#import "objcthemis/ssession.h"
#import "objcthemis/skeygen.h"

char server_key[]="\x55\x45\x43\x32\x00\x00\x00\x2d\x75\x58\x33\xd4\x02\x12\xdf\x1f\xe9\xea\x48\x11\xe1\xf9\x71\x8e\x24\x11\xcb\xfd\xc0\xa3\x6e\xd6\xac\x88\xb6\x44\xc2\x9a\x24\x84\xee\x50\x4c\x3e\xa0";
size_t server_key_length=45;

@implementation Transport

- (NSData *)publicKeyFor:(NSData *)binaryId error:(NSError **)error{
    NSString *id = [[NSString alloc] initWithData:binaryId encoding: NSUTF8StringEncoding];
    if([id isEqualToString: @"server"]){
        NSData* key = [[NSData alloc] initWithBytes:server_key  length:server_key_length];
    }
    return NULL;
}

@end

@implementation ViewController {
  SRWebSocket *webSocket;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self connectWebSocket];

  UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.messagesTextView addGestureRecognizer:tgr];

  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    UIViewAnimationOptions options = curve << 16;

    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
      CGRect frame = self.containerView.frame;
      frame.origin.y = CGRectGetMinY(endFrame) - CGRectGetHeight(self.containerView.frame);
      self.containerView.frame = frame;

      frame = self.messagesTextView.frame;
      frame.size.height = CGRectGetMinY(self.containerView.frame) - CGRectGetMinY(frame);
      self.messagesTextView.frame = frame;
    } completion:nil];
  }];
}

- (void)hideKeyboard {
  [self.view endEditing:YES];
}


#pragma mark - Connection

- (void)connectWebSocket {
  webSocket.delegate = nil;
  webSocket = nil;

  NSString *urlString = @"ws://192.168.43.213:8080";
  SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
  newWebSocket.delegate = self;

  [newWebSocket open];
}


#pragma mark - SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    webSocket = newWebSocket;
    TSKeyGen * keygenEC = [[TSKeyGen alloc] initWithAlgorithm:TSKeyGenAsymmetricAlgorithmEC];
    
    if (!keygenEC) {
        NSLog(@"%s Error occured while initializing object keygenEC", sel_getName(_cmd));
        return;
    }
    
    NSData *privateKey = keygenEC.privateKey;
    NSLog(@"EC private key: %@", privateKey);
    
    NSData *publicKey = keygenEC.publicKey;
    NSLog(@"EC public key:%@", publicKey);

  [webSocket send:[NSString stringWithFormat:@"%@:%@", [UIDevice currentDevice].name, [publicKey base64EncodedStringWithOptions:0]]];
    transport = [Transport alloc];
    session = [[TSSession alloc] initWithUserId:[[UIDevice currentDevice].name dataUsingEncoding:NSUTF8StringEncoding] privateKey:privateKey callbacks:transport];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
  [self connectWebSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
  [self connectWebSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
  self.messagesTextView.text = [NSString stringWithFormat:@"%@\n%@", self.messagesTextView.text, message];
}

- (IBAction)sendMessage:(id)sender {
  [webSocket send:self.messageTextField.text];
  self.messageTextField.text = nil;
}


#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self sendMessage:nil];
  return YES;
}

@end
