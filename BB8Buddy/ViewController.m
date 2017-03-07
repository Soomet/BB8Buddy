#import "ViewController.h"
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
#import <Affdex/Affdex.h>

@interface ViewController() <AFDXDetectorDelegate>

#if !TARGET_OS_SIMULATOR
@property (strong, nonatomic) RKConvenienceRobot* robot;
@property (strong, nonatomic) RUICalibrateGestureHandler *calibrateHandler;
#endif
@property (strong, nonatomic) AFDXDetector *detector;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *forceView;
@property (assign) BOOL drawFacePoints;
@property (strong, nonatomic) NSArray *facePoints;
@property (assign) AFDXCameraType cameraToUse;

@end

@implementation ViewController

- (void)detector:(AFDXDetector *)detector didStartDetectingFace:(AFDXFace *)face;
{
#if !TARGET_OS_SIMULATOR
    [self.robot setLEDWithRed:0.0 green:1.0 blue:0.0];
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
        [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
            [self.robot setLEDWithRed:0.0 green:1.0 blue:0.0];
#endif
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
                [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
#endif
                self.drawFacePoints = TRUE;
            });
        });
    });
}

- (void)detector:(AFDXDetector *)detector didStopDetectingFace:(AFDXFace *)face;
{
    [self.forceView setImage:nil];
#if !TARGET_OS_SIMULATOR
    [self.robot sendCommand:[RKRollCommand commandWithStopAtHeading:0]];
    [self.robot setLEDWithRed:1.0 green:0.0 blue:0.0];
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
        [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
            [self.robot setLEDWithRed:1.0 green:0.0 blue:0.0];
#endif
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if !TARGET_OS_SIMULATOR
                [self.robot setLEDWithRed:0.0 green:0.0 blue:0.0];
#endif
                self.drawFacePoints = FALSE;
            });
        });
    });
}

- (void)detector:(AFDXDetector *)detector hasResults:(NSMutableDictionary *)faces forImage:(UIImage *)image atTime:(NSTimeInterval)time;
{
    if (nil == faces)
    {
        // put up frame in view
        UIImage *newImage = image;
        
        if (self.drawFacePoints)
        {
            newImage = [AFDXDetector imageByDrawingPoints:self.facePoints
                                            andRectangles:nil
                                                andImages:nil
                                               withRadius:2.0
                                          usingPointColor:[UIColor whiteColor]
                                      usingRectangleColor:[UIColor greenColor]
                                          usingImageRects:nil
                                                  onImage:image];
        }

        // flip image if the front camera is being used so that the perspective is mirrored.
        if (self.cameraToUse == AFDX_CAMERA_FRONT)
        {
            UIImage *flippedImage = [UIImage imageWithCGImage:newImage.CGImage
                                                        scale:newImage.scale
                                                  orientation:UIImageOrientationUpMirrored];
            [self.imageView setImage:flippedImage];
        }
        else
        {
            [self.imageView setImage:newImage];
        }
    }
    else if ([faces count] > 0)
    {
        NSString *firstFaceKey = [[faces allKeys] objectAtIndex:0];
        AFDXFace *face = [faces objectForKey:firstFaceKey];
        self.facePoints = face.facePoints;

        if (face.expressions.browFurrow > 20)
        {
            // negative
#if !TARGET_OS_SIMULATOR
            [self.robot sendCommand:[RKRollCommand commandWithHeading:180 andVelocity:face.expressions.browFurrow / 100.0]];
#endif
            [self.forceView setImage:[UIImage imageNamed:@"darkside.png"]];
        }
        else if (face.expressions.browRaise > 20)
        {
            // Positive
#if !TARGET_OS_SIMULATOR
            [self.robot sendCommand:[RKRollCommand commandWithHeading:0 andVelocity:face.expressions.browRaise / 100.0]];
#endif
            [self.forceView setImage:[UIImage imageNamed:@"lightside.png"]];
        }
        else
        {
            // Neutral
#if !TARGET_OS_SIMULATOR
            [self.robot sendCommand:[RKRollCommand commandWithStopAtHeading:0]];
#endif
            [self.forceView setImage:nil];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    

    self.cameraToUse = AFDX_CAMERA_FRONT;

#if !TARGET_OS_SIMULATOR
    self.calibrateHandler = [[RUICalibrateGestureHandler alloc] initWithView:self.view];
    
    // hook up for robot state changes
    [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
#endif

    self.detector = [[AFDXDetector alloc] initWithDelegate:self usingCamera:self.cameraToUse maximumFaces:1 faceMode:LARGE_FACES];
    self.detector.browRaise = YES;
    self.detector.browFurrow = YES;
    [self.detector start];

#if TARGET_OS_SIMULATOR
    [self.forceView setImage:[UIImage imageNamed:@"lightside.png"]];
#endif
}


- (void)appDidBecomeActive:(NSNotification*)notification
{
#if !TARGET_OS_SIMULATOR
    [RKRobotDiscoveryAgent startDiscovery];
#endif
}


- (void)appWillResignActive:(NSNotification*)notification
{
#if !TARGET_OS_SIMULATOR
    [RKRobotDiscoveryAgent stopDiscovery];
    [RKRobotDiscoveryAgent disconnectAll];
#endif
}

- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)n
{
#if !TARGET_OS_SIMULATOR
    switch(n.type)
    {
        case RKRobotConnecting:
            [self handleConnecting];
            break;
        case RKRobotOnline:
        {
            // Do not allow the robot to connect if the application is not running
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:n.robot];
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
            {
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
#endif
}

- (void)handleConnecting
{
    // Handle when a robot is connecting here
}

- (void)handleConnected
{
#if !TARGET_OS_SIMULATOR
    [_calibrateHandler setRobot:_robot.robot];
#endif
}

- (void)handleDisconnected
{
#if !TARGET_OS_SIMULATOR
    [_calibrateHandler setRobot:nil];
#endif
}

- (IBAction)zeroPressed:(id)sender
{
#if !TARGET_OS_SIMULATOR
    [_robot driveWithHeading:0.0 andVelocity:0.5];
#endif
}

- (IBAction)ninetyPressed:(id)sender
{
#if !TARGET_OS_SIMULATOR
    [_robot driveWithHeading:90 andVelocity:0.5];
#endif
}

- (IBAction)oneEightyPressed:(id)sender
{
#if !TARGET_OS_SIMULATOR
    [_robot driveWithHeading:180 andVelocity:0.5];
#endif
}

- (IBAction)twoSeventyPressed:(id)sender
{
#if !TARGET_OS_SIMULATOR
    [_robot driveWithHeading:270.0 andVelocity:0.5];
#endif
}

- (IBAction)stopPressed:(id)sender
{
#if !TARGET_OS_SIMULATOR
    [_robot stop];
#endif
}

@end
