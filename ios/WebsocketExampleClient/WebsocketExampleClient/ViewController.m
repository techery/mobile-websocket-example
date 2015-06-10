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
    return nil;
}

@end


@interface ViewController ()

@property (nonatomic, strong) SRWebSocket * webSocket;

@property (nonatomic, strong) Transport * transport;
@property (nonatomic, strong) TSSession * session;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectWebSocket];
}


#pragma mark - Connection

- (void)connectWebSocket {
    [self loggingEvent:@"connecting..."];
    NSString * urlString = @"ws://127.0.0.1:8080";
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
    self.webSocket.delegate = self;

    [self.webSocket open];
}


#pragma mark - Themis

- (void)initializeSession {
    // generate keys
    
    TSKeyGen * keygenEC = [[TSKeyGen alloc] initWithAlgorithm:TSKeyGenAsymmetricAlgorithmEC];
    if (!keygenEC) {
        [self loggingEvent:@"Error while initializing keygen"];
        NSLog(@"%s Error occured while initializing object keygenEC", sel_getName(_cmd));
        return;
    }

    NSData * privateKey = keygenEC.privateKey;
    NSData * publicKey = keygenEC.publicKey;

    // send public key in format
    // name : publicKey

    NSString * handshakeMessage = [NSString stringWithFormat:@"%@:%@", [UIDevice currentDevice].name, [publicKey base64EncodedStringWithOptions:0]];
    [self loggingEvent:@"sending handshakeMessage"];
    NSLog(@"sending handshakeMessage %@", handshakeMessage);
    [self.webSocket send:handshakeMessage];


    // connect request
    self.transport = [Transport new];
    self.session = [[TSSession alloc] initWithUserId:[[UIDevice currentDevice].name dataUsingEncoding:NSUTF8StringEncoding]
                                          privateKey:privateKey
                                           callbacks:self.transport];
    NSError * error = nil;
    NSData * sessionEstablishingData = [self.session connectRequest:&error];
    if (error) {
        [self loggingEvent:[NSString stringWithFormat:@"Error while handshake %@", error]];
        return;
    }

    NSString * sessionEstablishingString = [sessionEstablishingData base64EncodedStringWithOptions:0];
    [self loggingEvent:@"sending establishing message"];
    NSLog(@"sending establishing message %@", sessionEstablishingString);
    [self.webSocket send:sessionEstablishingString];
}


#pragma mark - SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    NSLog(@"%s", sel_getName(_cmd));
    [self initializeSession];
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"%s", sel_getName(_cmd));

    if (error.code == 61) {
        [self loggingEvent:[NSString stringWithFormat:@"Error %@", error]];
        NSLog(@"Error %@", error);
        NSLog(@"Please, start ruby server, using guide https://github.com/cossacklabs/mobile-websocket-example/tree/master/server");
        return;
    }
    
    // reconnect
    [self connectWebSocket];
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"%s", sel_getName(_cmd));

    // reconnect
    //[self connectWebSocket];
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"%s", sel_getName(_cmd));
    [self loggingEvent:@"response received"];

    NSError * error = nil;

    NSData * receivedData = [[NSData alloc] initWithBase64EncodedString:message options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData * unwrappedMessage = [self.session unwrapData:receivedData error:&error];

    if (error) {
        [self loggingEvent:[NSString stringWithFormat:@"Error on unwrapping message %@", error]];
        NSLog(@"Error on unwrapping message %@", error);
        return;
    }

    // re-send message?
    if (![self.session isSessionEstablished] && unwrappedMessage) {
        NSString * unwrappedStringMessage = [unwrappedMessage base64EncodedStringWithOptions:0];
        [self loggingEvent:@"sending establishing message"];
        NSLog(@"sending establishing message %@", unwrappedStringMessage);
        [webSocket send:unwrappedStringMessage];
        return;
    }

    NSString * unwrappedString = [[NSString alloc] initWithData:unwrappedMessage encoding:NSUTF8StringEncoding];
    [self loggingEvent:unwrappedString];
}


#pragma mark - actions

- (IBAction)sendMessage:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    NSData * dataToSend = [self.messageTextField.text dataUsingEncoding:NSUTF8StringEncoding];

    if (!dataToSend) {
        // no message, no sending
        NSLog(@"there is nothing to send, cancelling");
        return;
    }
    
    if (!self.webSocket) {
        NSLog(@"socket is not connected");
        [self loggingEvent:@"socket is not connected"];
        return;
    }

    // wrap data
    NSError * error;
    NSData * wrappedData = [self.session wrapData:dataToSend error:&error];

    if (!wrappedData || error) {
        [self loggingEvent:[NSString stringWithFormat:@"Error on wrapping message %@", error]];
        NSLog(@"Error on wrapping message %@", error);
        return;
    }

    NSString * wrappedStringMessage = [wrappedData base64EncodedStringWithOptions:0];
    [self loggingEvent:@"sending message..."];
    [self.webSocket send:wrappedStringMessage];
}


- (IBAction)reconnect:(id)sender {
    [self loggingEvent:@"reconnecting..."];
    [self connectWebSocket];
}


- (void)loggingEvent:(NSString * )string {
    self.messagesTextView.text = [NSString stringWithFormat:@"%@\n* %@", self.messagesTextView.text, string];

    // scroll to bottom
    NSRange bottom = NSMakeRange(self.messagesTextView.text.length - 1, 1);
    [self.messagesTextView scrollRangeToVisible:bottom];
}


#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage:nil];
    return YES;
}

@end
