//
//  RCTMbark.h
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-07.
//

#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>

/// Provides a React Native friendly interface to the mbark iOS SDK's methods.
/// Please see https://github.com/mbark-app-inc/mbark-sdk for documentation on the native methods this module
/// makes available.

@interface RCTMbark : RCTEventEmitter <RCTBridgeModule>
@end
