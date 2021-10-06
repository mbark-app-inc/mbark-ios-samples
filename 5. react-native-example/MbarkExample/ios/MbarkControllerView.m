//
//  MbarkControllerView.m
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-09.
//

#import "MbarkControllerView.h"
#import <Mbark/Mbark.h>

@interface MbarkControllerView ()

@property (nonatomic, retain) NSDictionary *config;
@property (nonatomic, weak) MbarkViewController *mbarkViewController;

@end

@implementation MbarkControllerView

- (void)setConfig:(NSDictionary *)config {
  _config = config;
  [self setNeedsLayout];
}

- (NSString *)screenId {
  return self.config[@"screenId"];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  if (!self.mbarkViewController) {
    [self embed];
    return;
  }
  self.mbarkViewController.view.frame = self.bounds;
}

- (void) embed {
  if (!self.parentViewController || !self.screenId) {
    return;
  }
  self.mbarkViewController = [Mbark userViewForMbarkId:self.screenId onLoaded:^(BOOL success) {
    if (!success || !self.mbarkViewController) {
      return;
    }
    [self.parentViewController addChildViewController:self.mbarkViewController];
    self.mbarkViewController.view.frame = self.bounds;
    [self addSubview:self.mbarkViewController.view];
    [self.mbarkViewController didMoveToParentViewController:self.parentViewController];
  }];
}

- (UIViewController *)parentViewController {
  UIResponder *parentResponder = self;
  while (parentResponder) {
    parentResponder = parentResponder.nextResponder;
    if ([parentResponder isKindOfClass: [UIViewController class]]) {
      return (UIViewController *)parentResponder;
    }
  }
  return nil;
}

@end
