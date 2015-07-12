//
//  ViewController.h
//  WebsocketExampleClient
//

#import <UIKit/UIKit.h>
#import <SocketRocket/SRWebSocket.h>
#import "objcthemis/ssession.h"


@class TSCellSeal;


@interface Transport : TSSessionTransportInterface

@end

@interface ViewController : UIViewController <SRWebSocketDelegate, UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextView *messagesTextView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

- (IBAction)sendMessage:(id)sender;

- (IBAction)reconnect:(id)sender;

@end
