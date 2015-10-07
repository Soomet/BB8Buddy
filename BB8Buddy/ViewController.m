#import "ViewController.h"
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
#import <Affdex/Affdex.h>

@interface ViewController() <AFDXDetectorDelegate>

@property (strong, nonatomic) RKConvenienceRobot* robot;
@property (strong, nonatomic) RUICalibrateGestureHandler *calibrateHandler;
@property (strong, nonatomic) AFDXDetector *detector;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)detector:(AFDXDetector *)detector didStartDetectingFace:(AFDXFace *)face;
{
    [self.robot setLEDWithRed:0.0 green:1.0 blue:0.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.robot setLEDWithRed:0.0 green:1.0 blue:0.0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
            });
        });
    });
}

- (void)detector:(AFDXDetector *)detector didStopDetectingFace:(AFDXFace *)face;
{
    [self.robot sendCommand:[RKRollCommand commandWithStopAtHeading:0]];
    [self.robot setLEDWithRed:1.0 green:0.0 blue:0.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.robot setLEDWithRed:1.0 green:0.0 blue:0.0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
            });
        });
    });
}

- (void)detector:(AFDXDetector *)detector hasResults:(NSMutableDictionary *)faces forImage:(UIImage *)image atTime:(NSTimeInterval)time;
{
    if (nil == faces) {
        // put up frame in view
        [self.imageView setImage:image];
    } else if ([faces count] > 0) {
        NSString *firstFaceKey = [[faces allKeys] objectAtIndex:0];
        AFDXFace *face = [faces objectForKey:firstFaceKey];

        if (face.browFurrowScore > 20) {
            [self.robot sendCommand:[RKRollCommand commandWithHeading:180 andVelocity:face.browFurrowScore / 100.0]];
        }
        else if (face.browRaiseScore > 20)
        {
            [self.robot sendCommand:[RKRollCommand commandWithHeading:0 andVelocity:face.browRaiseScore / 100.0]];
        }
        else
        {
            [self.robot sendCommand:[RKRollCommand commandWithStopAtHeading:0]];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    
    self.calibrateHandler = [[RUICalibrateGestureHandler alloc] initWithView:self.view];
    
    // hook up for robot state changes
    [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
    
    self.detector = [[AFDXDetector alloc] initWithDelegate:self usingCamera:AFDX_CAMERA_FRONT maximumFaces:1];
    self.detector.licensePath = [[NSBundle mainBundle] pathForResource:@"sdk" ofType:@"license"];
    self.detector.browRaise = YES;
    self.detector.browFurrow = YES;
    [self.detector start];
}


- (void)appDidBecomeActive:(NSNotification*)notification {
    [RKRobotDiscoveryAgent startDiscovery];
}


- (void)appWillResignActive:(NSNotification*)notification {
    [RKRobotDiscoveryAgent stopDiscovery];
    [RKRobotDiscoveryAgent disconnectAll];
}

- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)n {
    switch(n.type) {
        case RKRobotConnecting:
            [self handleConnecting];
            break;
        case RKRobotOnline: {
            // Do not allow the robot to connect if the application is not running
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:n.robot];
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [convenience disconnect];
                return;
            }
            self.robot = convenience;
            [self handleConnected];
            break;
        }
        case RKRobotDisconnected:
            [self handleDisconnected];
            self.robot = nil;
            [RKRobotDiscoveryAgent startDiscovery];
            break;
        default:
            break;
    }
}

- (void)handleConnecting {
    // Handle when a robot is connecting here
}

- (void)handleConnected {
    [_calibrateHandler setRobot:_robot.robot];
}

- (void)handleDisconnected {
    [_calibrateHandler setRobot:nil];
}

- (IBAction)zeroPressed:(id)sender {
    [_robot driveWithHeading:0.0 andVelocity:0.5];
}

- (IBAction)ninetyPressed:(id)sender {
    [_robot driveWithHeading:90 andVelocity:0.5];
}

- (IBAction)oneEightyPressed:(id)sender {
    [_robot driveWithHeading:180 andVelocity:0.5];
}

- (IBAction)twoSeventyPressed:(id)sender {
    [_robot driveWithHeading:270.0 andVelocity:0.5];
}

- (IBAction)stopPressed:(id)sender {
    [_robot stop];
}

@end
