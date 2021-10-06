//
//  RCTMbarkViewManager.m
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-08.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <React/RCTUIManager.h>
#import "RCTMbark.h"
#import "MbarkControllerView.h"

/// A simple `RCTViewManager` used to provide React Native access to `MbarkControllerView`

@interface RCTMbarkViewManager : RCTViewManager
@end

@implementation RCTMbarkViewManager

- (UIView *)view {
  return [MbarkControllerView new];
}

@end
