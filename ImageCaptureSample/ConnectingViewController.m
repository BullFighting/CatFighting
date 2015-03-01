//
//  ConnectingViewController.m
//  ImageViewerSample
//
//  Copyright (c) 2014 Olympus Imaging Corporation. All rights reserved.
//

#import "ConnectingViewController.h"
#import "AppDelegate.h"
#import "BLEBaseClass.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define CONNECT_BUTTON 0
#define DISCONNECT_BUTTON 1
#define LED_ON_BUTTON 2
#define LED_OFF_BUTTON 3

#define UUID_VSP_SERVICE					@"569a1101-b87f-490c-92cb-11ba5ea5167c" //VSP
#define UUID_RX                             @"569a2001-b87f-490c-92cb-11ba5ea5167c" //RX
#define UUID_TX								@"569a2000-b87f-490c-92cb-11ba5ea5167c" //TX

static NSString *const kNextViewControllerIdentifier = @"ImageCapture";

@interface ConnectingViewController () <BLEDeviceClassDelegate>
@property (strong)		BLEBaseClass*	BaseClass;
@property (readwrite)	BLEDeviceClass*	Device;

@property (weak, nonatomic) IBOutlet UILabel *cameraKitVersionLabel;

@end


@implementation ConnectingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnectionStateNotification:) name:kAppDelegateCameraDidChangeConnectionStateNotification object:nil];

	self.cameraKitVersionLabel.text = OLYCameraKitVersion;
 
    [self connect];
    
}

//------------------------------------------------------------------------------------------
//	readもしくはindicateもしくはnotifyにてキャラクタリスティックの値を読み込んだ時に呼ばれる
//------------------------------------------------------------------------------------------
- (void)didUpdateValueForCharacteristic:(BLEDeviceClass *)device Characteristic:(CBCharacteristic *)characteristic
{
    if (device == _Device)	{
        //	キャラクタリスティックを扱う為のクラスを取得し
        //	通知されたキャラクタリスティックと比較し同じであれば
        //	bufに結果を格納
        //iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        if (characteristic == rx)	{
            //			uint8_t*	buf = (uint8_t*)[characteristic.value bytes]; //bufに結果が入る
            //            NSLog(@"value=%@",characteristic.value);
            return;
        }
        
        //Device->iPhone
        CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
        if (characteristic == tx)	{
            //            NSLog(@"Receive value=%@",characteristic.value);
            uint8_t*	buf = (uint8_t*)[characteristic.value bytes]; //bufに結果が入る
            NSLog(@"buf[0]%d", buf[0]);
            return;
        }
        
    }
}


//////////////////////////////////////////////////////////////
//  connect
//////////////////////////////////////////////////////////////
-(void)connect{
    //	UUID_DEMO_SERVICEサービスを持っているデバイスに接続する
    _Device = [_BaseClass connectService:UUID_VSP_SERVICE];
    if (_Device)	{
        //	接続されたのでスキャンを停止する
        [_BaseClass scanStop];
        //	キャラクタリスティックの値を読み込んだときに自身をデリゲートに指定
        _Device.delegate = self;
        
        //        [_BaseClass printDevices];
        
        //ボタンの状態変更
//        _connectButton.enabled = FALSE;
//        _disconnectButton.enabled = TRUE;
//        _ledOnButton.enabled = TRUE;
//        _ledOffButton.enabled = TRUE;
        
        //	tx(Device->iPhone)のnotifyをセット
        CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
        if (tx)	{
            //            [_Device readRequest:tx];
            [_Device notifyRequest:tx];
        }
    }
}

//////////////////////////////////////////////////////////////
//  ボタンクリックイベント
//////////////////////////////////////////////////////////////
-(IBAction)onButtonClick:(UIButton*)sender{
    if(sender.tag==CONNECT_BUTTON){
        [self connect];
    }else if(sender.tag==DISCONNECT_BUTTON){
        //[self disconnect];
    }else if(sender.tag==LED_ON_BUTTON){
        //[self sendOn];
    }else if(sender.tag==LED_OFF_BUTTON){
        //[self sendOff];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)didChangeConnectionStateNotification:(NSNotification *)notification
{
	NSString *state = notification.userInfo[kConnectionStateKey];
	if (state == kConnectionStateConnected) {
		[self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:kNextViewControllerIdentifier] animated:NO completion:^{
			if (!AppDelegateCamera().connected) {
				[self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
			}
		}];
	}
	else if (state == kConnectionStateDisconnected) {
		if (self.presentedViewController) {
			[self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
		}
	}
}

@end
