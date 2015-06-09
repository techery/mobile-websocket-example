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


char server_key[] = "\x55\x45\x43\x32\x00\x00\x00\x2d\x75\x58\x33\xd4\x02\x12\xdf\x1f\xe9\xea\x48\x11\xe1\xf9\x71\x8e\x24\x11\xcb\xfd\xc0\xa3\x6e\xd6\xac\x88\xb6\x44\xc2\x9a\x24\x84\xee\x50\x4c\x3e\xa0";
size_t server_key_length = 45;


@implementation Transport

- (NSData *)publicKeyFor:(NSData *)binaryId error:(NSError **)error {
    NSString * id = [[NSString alloc] initWithData:binaryId encoding:NSUTF8StringEncoding];
    if ([id isEqualToString:@"server"]) {
        NSData * key = [[NSData alloc] initWithBytes:server_key length:server_key_length];
        return key;
    }
    return NULL;
}

@end


@implementation ViewController {
    SRWebSocket * webSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectWebSocket];
}


#pragma mark - Connection

- (void)connectWebSocket {
    webSocket.delegate = nil;
    webSocket = nil;

    NSString * urlString = @"ws://127.0.0.1:8080";
    SRWebSocket * newWebSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
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

    NSData * privateKey = keygenEC.privateKey;
    NSLog(@"EC private key: %@", privateKey);

    NSData * publicKey = keygenEC.publicKey;
    NSLog(@"EC public key:%@", publicKey);

    [webSocket send:[NSString stringWithFormat:@"%@:%@", [UIDevice currentDevice].name, [publicKey base64EncodedStringWithOptions:0]]];
    transport = [[Transport alloc] init];
    session = [[TSSession alloc] initWithUserId:[[UIDevice currentDevice].name dataUsingEncoding:NSUTF8StringEncoding] privateKey:privateKey callbacks:transport];
    NSError * error = NULL;
    NSData * data_to_send = [session connectRequest:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    [webSocket send:[NSString stringWithFormat:@"%@", [data_to_send base64EncodedStringWithOptions:0]]];
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self connectWebSocket];
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self connectWebSocket];
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSError * error = NULL;
    NSData * umessage = [session unwrapData:[[NSData alloc] initWithBase64EncodedString:message options:1] error:&error];
    if ([error code] < 0) { //must be corrected to "error" with new objthemis
        NSLog(@"%@", error);
        return;
    }
    if (![session isSessionEstablished]) {
        [webSocket send:[NSString stringWithFormat:@"%@", [umessage base64EncodedStringWithOptions:0]]];
        return;
    }
    if ([umessage length] == 0)return;
    self.messagesTextView.text = [NSString stringWithFormat:@"%@\n%@", self.messagesTextView.text, [[NSString alloc] initWithData:umessage encoding:NSUTF8StringEncoding]];
}


- (IBAction)sendMessage:(id)sender {
    NSError * error;
    [webSocket send:[[session wrapData:[self.messageTextField.text dataUsingEncoding:NSUTF8StringEncoding] error:&error] base64EncodedStringWithOptions:0]];
    self.messageTextField.text = nil;
}


#pragma mark - UITextField delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage:nil];
    return YES;
}

@end
