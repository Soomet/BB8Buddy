![Affectiva Logo](http://developer.affectiva.com/images/logo.png)

###Copyright (c) 2016 Affectiva Inc. <br/>
The Affdex SDK is covered by our [SDK License Agreement](http://developer.affectiva.com/sdklicense)<br/>
The AffdexMe app is covered by the MIT license.  See the file [license.txt](license.txt) for copying permission.

*****************************

**BB8Budd**y is an iOS application that demonstrates how to integrate the Affectiva iOS SDK with the Sphero SDK to control the BB-8 droid with your facial expressions.

For developer documentation, sample code, and other information, please visit our website:
http://developer.affectiva.com

The SDK License Agreement is available at:
http://developer.affectiva.com/sdklicense

This is an Xcode 7 project.

In order to use this project, you will need to:
- Obtain the Sphero SDK for iOS at http://developer.gosphero.com and place the contents at the root level of the project folder.
- Obtain the Affectiva iOS SDK (visit http://www.affectiva.com/solutions/apis-sdks/)
- Have a valid CocoaPods installation on your machine
- Install the Affdex SDK on your machine using the Podfile:
```
pod install
```

- Open the Xcode workspace file BB8Buddy.xcworkspace -- not the .xcodeproj file.
- Build the project for device. 
- Run the app and pair it with BB-8, then smile or frown!
