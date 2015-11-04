//
//  ViewController.m
//  WebsocketExampleClient
//
//

#import <themis/objcthemis/scell_seal.h>
#import <themis/objcthemis/skeygen.h>
#import "ViewController.h"


NSString * const kServerKey = @"VUVDMgAAAC11WDPUAhLfH+nqSBHh+XGOJBHL/cCjbtasiLZEwpokhO5QTD6g";
NSString * const kHistoryStoringKey = @"kHistoryStoringKey";


@implementation Transport

- (NSData *)publicKeyFor:(NSData *)binaryId error:(NSError **)error {
    NSString * stringFromData = [[NSString alloc] initWithData:binaryId encoding:NSUTF8StringEncoding];
    if ([stringFromData isEqualToString:@"server"]) {
        NSData * key = [[NSData alloc] initWithBase64EncodedString:kServerKey options:NSDataBase64DecodingIgnoreUnknownCharacters];
        return key;
    }
    return nil;
}

@end


@interface ViewController ()

@property (nonatomic, strong) SRWebSocket * webSocket;

@property (nonatomic, strong) Transport * transport;
@property (nonatomic, strong) TSSession * session;
@property (nonatomic, strong) TSCellSeal * secureStorageEnryptor;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self readHistory];
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

    NSString * name = [UIDevice currentDevice].name;
    NSString * handshakeMessage = [NSString stringWithFormat:@"%@:%@", name, [publicKey base64EncodedStringWithOptions:0]];
    [self loggingEvent:@"sending handshakeMessage"];
    NSLog(@"sending handshakeMessage %@", handshakeMessage);
    [self.webSocket send:handshakeMessage];


    // send establishment message
    self.transport = [Transport new];
    self.session = [[TSSession alloc] initWithUserId:[name dataUsingEncoding:NSUTF8StringEncoding]
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

    NSData * receivedData = [[NSData alloc] initWithBase64EncodedString:message
                                                                options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData * unwrappedMessage = [self.session unwrapData:receivedData error:&error];

    if (error) {
        [self loggingEvent:[NSString stringWithFormat:@"Error on unwrapping message %@", error]];
        NSLog(@"Error on unwrapping message %@", error);
        return;
    }

    // re-send message?
    if (![self.session isSessionEstablished] && unwrappedMessage) {
        NSString * unwrappedStringMessage = [unwrappedMessage base64EncodedStringWithOptions:0];
        [self loggingEvent:@"responding on establishing message"];
        NSLog(@"responding establishing message %@", unwrappedStringMessage);
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
    
    self.messageTextField.text = nil;
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

    // saving to storage
    [self saveHistory:string];
}


- (void)saveHistory:(NSString *)string {
    // create encryptor if there's no
    [self createSecureStorage];

    // encrypt event
    NSError * error = nil;
    NSString * message = [NSString stringWithFormat:@"%@ %@", [NSDate date], string];
    NSData * encryptedEvent = [self.secureStorageEnryptor wrapData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                           context:nil
                                                             error:&error];
    if (!encryptedEvent || error) {
        NSLog(@"Error on encrypting message %@", error);
        return;
    }

    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

    // check if history is already presented
    NSMutableArray * history = [[userDefaults valueForKey:kHistoryStoringKey] mutableCopy];
    if (!history) {
        history = [NSMutableArray new];
    }

    // add encrypted object to history
    [history addObject:encryptedEvent];

    // add history to storage
    [userDefaults setObject:history forKey:kHistoryStoringKey];
}


- (void)readHistory {
    NSLog(@"Previous message history on this client...");
    [self createSecureStorage];

    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * history = [userDefaults valueForKey:kHistoryStoringKey];

    [history enumerateObjectsUsingBlock:^(NSData * encryptedData, NSUInteger idx, BOOL * stop) {
        NSError * error = nil;
        NSData * decryptedMessage = [self.secureStorageEnryptor unwrapData:encryptedData
                                                 context:nil
                                                   error:&error];

        if (error) {
            NSLog(@"Error on decrypting message %@", error);
        } else {
            NSString * resultString = [[NSString alloc] initWithData:decryptedMessage
                                                            encoding:NSUTF8StringEncoding];
            NSLog(@"Message decrypted:\n-- %@", resultString);
        }
    }];
    NSLog(@"End of history\n\n");
}


- (void)createSecureStorage {
    // create encryptor if there's no
    if (!self.secureStorageEnryptor) {

        // you should NEVER use uuid as encryption key ;)
        NSString * encryptionKey = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        self.secureStorageEnryptor = [[TSCellSeal alloc] initWithKey:[encryptionKey dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage:nil];
    return YES;
}

@end
