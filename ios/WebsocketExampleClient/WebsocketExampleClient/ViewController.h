//
//  ViewController.h
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SocketRocket/SRWebSocket.h>
#import "objcthemis/ssession.h"


@interface Transport : TSSessionTransportInterface

@end

@interface ViewController : UIViewController <SRWebSocketDelegate, UITextFieldDelegate>{
    Transport* transport;
    TSSession* session;
}

@property (weak, nonatomic) IBOutlet UITextView *messagesTextView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;



- (IBAction)sendMessage:(id)sender;

@end
