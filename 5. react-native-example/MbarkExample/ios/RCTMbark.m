//
//  RCTMbark.m
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-07.
//

#import "RCTMbark.h"
#import <React/RCTLog.h>
#import <Mbark/Mbark.h>

@interface RCTMbark ()

@property (nonatomic, retain) NSMutableArray<MbarkActionHandler *> *mbarkActionHandlers;
@property (nonatomic, retain) MbarkPurchaseActionHandler *mbarkPurchaseActionHandler;

@end

@implementation RCTMbark
{
  bool hasListeners;
}

/// State
- (NSMutableArray<MbarkActionHandler *> *)mbarkActionHandlers {
    if (!_mbarkActionHandlers) {
      _mbarkActionHandlers = [NSMutableArray<MbarkActionHandler *> new];
    }
    return _mbarkActionHandlers;
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

/// Exports a module named Mbark
RCT_EXPORT_MODULE(Mbark);

- (NSArray<NSString *> *)supportedEvents {
  return @[@"mbarkEvent"];
}

#pragma mark - Initialize

/// Initializes the Mbark SDK using an `Mbark-Info.plist` file to provide the configuration
RCT_EXPORT_METHOD(initialize) {
  [Mbark initializeSDKWithInstanceName:@"React-example"
                      selectedLanguage:nil];
}

/// Initializes the Mbark SDK by manually providing a config id and api key.
RCT_EXPORT_METHOD(initializeWithInstanceName:(nonnull NSString *)instanceName configId:(nonnull NSString *)configId apiKey:(nonnull NSString *)apiKey) {
  [Mbark initializeSDKWithInstanceName:instanceName
                        remoteConfigId:configId
                      productionAPIKey:nil
                     developmentAPIKey:apiKey
                      selectedLanguage:nil];
}

#pragma mark - Properties

RCT_EXPORT_METHOD(isActive:(RCTPromiseResolveBlock)resolve rejector: (RCTPromiseRejectBlock)reject) {
  resolve(@(Mbark.isActive));
}

#pragma mark - Event Tracking

/// Tracks Mbark events
RCT_EXPORT_METHOD(trackEvent:(double)eventType step:(nullable NSString *)step component:(nullable NSString *)component data: (nullable NSDictionary *)data) {

  MbarkEventData* eventData = [self eventDataFromDictionary:data];

  [Mbark trackWithEventType:(MbarkEventType)eventType
                       step:step
                  component:component
                       data:eventData];
}

/// Track singular Mbark events
RCT_EXPORT_METHOD(trackOnce:(double)eventType step:(nullable NSString *)step component:(nullable NSString *)component data: (nullable NSDictionary *)data) {

  MbarkEventData* eventData = [self eventDataFromDictionary:data];

  [Mbark trackOnceWithEventType:(MbarkEventType)eventType
                           step:step
                      component:component
                           data:eventData];
}

/// Helper method used to simplify tracking flow starts
RCT_EXPORT_METHOD(trackFlowStart) {
  [Mbark trackFlowStart];
}

/// Helper method used to simplify tracking flow ends
RCT_EXPORT_METHOD(trackFlowEnd) {
  [Mbark trackFlowEnd];
}

/// Helper method used to simplify tracking step views - used in cases where we can't register the step with an mbark id
/// for example, SSO-flows
RCT_EXPORT_METHOD(trackStepView:(nonnull NSString *)step data:(nullable NSDictionary *)data) {
  MbarkEventData* eventData = [self eventDataFromDictionary:data];

  [Mbark trackStepView:step
                  data:eventData];
}

/// Helper method used to simplify tracking new user authentication events
RCT_EXPORT_METHOD(trackAuthenticationForNewUser) {
  [Mbark trackAuthenticationForNewUser];
}

/// Helper method used to simplify tracking existing user authentication events
RCT_EXPORT_METHOD(trackAuthenticationForExistingUser) {
  [Mbark trackAuthenticationForExistingUser];
}

/// Helper method used to simplify tracking accept events
RCT_EXPORT_METHOD(trackAcceptWithStep:(nullable NSString *)step component:(nullable NSString *)component shouldTrackOnce:(BOOL) shouldTrackOnce) {
  [Mbark trackAcceptWithStep:step component:component shouldTrackOnce:shouldTrackOnce];
}

/// Helper method used to simplify tracking reject events
RCT_EXPORT_METHOD(trackRejectWithStep:(nullable NSString *)step component:(nullable NSString *)component shouldTrackOnce:(BOOL) shouldTrackOnce) {
  [Mbark trackRejectWithStep:step component:component shouldTrackOnce:shouldTrackOnce];
}

/// Helper method used to simplify tracking tap events
RCT_EXPORT_METHOD(trackTapWithStep:(nullable NSString *)step component:(nullable NSString *)component data:(nullable NSDictionary *)data) {

  MbarkEventData* eventData = [self eventDataFromDictionary:data];

  [Mbark trackTapWithStep:step
                component:component
                     data:eventData];
}

/// Helper method used to simplify tracking input events
RCT_EXPORT_METHOD(trackInputWithStep:(nullable NSString *)step component:(nullable NSString *)component data:(nullable NSDictionary *)data) {
  MbarkEventData* eventData = [self eventDataFromDictionary:data];

  [Mbark trackInputWithStep:step
                  component:component
                       data:eventData];
}

/// Helper method used to simplify tracking app loading
RCT_EXPORT_METHOD(trackAppLoading) {
  [Mbark trackAppLoading];
}

#pragma mark - Rendered UI

/// Helper method used to launch a complete Mbark onboarding flow
RCT_EXPORT_METHOD(presentOnboardingWithStartingViewId:(nonnull NSString *)viewId) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UINavigationController *testFlow = [Mbark userFlowWithStartingViewId:viewId onLoaded:^(BOOL success) {
    }];

    if (!testFlow) { return; }

    testFlow.modalPresentationStyle = UIModalPresentationFullScreen;
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:testFlow animated:YES completion:nil];
  });
}

/// Please see `RCTMbarkViewManager` to see how to create an embeddable, single Mbark view controller

#pragma mark - Action Handlers

/// Adds an action handler

RCT_EXPORT_METHOD(registerEventForId:(NSString *)eventId) {
  MbarkActionHandler *actionHandler = [[MbarkActionHandler alloc] initWithId:eventId handler:^{
      [self sendEventWithName:@"mbarkEvent" body:@{ @"id": eventId }];
  }];
  [Mbark addActionHandler:actionHandler];
  [self.mbarkActionHandlers addObject:actionHandler];
}

/// Mark action handler as finished

RCT_EXPORT_METHOD(markEventCompleteForEventId:(NSString *)eventId success:(BOOL)success) {
  for (MbarkActionHandler *handler in self.mbarkActionHandlers) {
    if (handler.id == eventId) {
      [handler finishWithSuccess:success];
      break;
    }
  }
}

/// Removes an action handler
RCT_EXPORT_METHOD(unregisterEventForId:(nonnull NSString *)eventId) {
  [Mbark removeActionHandlerForId:eventId];

  for (MbarkActionHandler *handler in self.mbarkActionHandlers) {
    if (handler.id == eventId) {
      [self.mbarkActionHandlers removeObject: handler];
      break;
    }
  }
}

/// Adds a purchase action handler
RCT_EXPORT_METHOD(registerPurchaseEventForId:(NSString *)eventId) {
  MbarkPurchaseActionHandler *purchaseActionHandler = [[MbarkPurchaseActionHandler alloc] initWithId:eventId
                                                                                             handler:^(NSString * _Nonnull sku) {
    [self sendEventWithName:@"mbarkEvent" body:@{ @"id": eventId, @"sku": sku }];
  }];
  [Mbark addPurchaseActionHandler:purchaseActionHandler];
  self.mbarkPurchaseActionHandler = purchaseActionHandler;
}

RCT_EXPORT_METHOD(markPurchaseEventCompleteWithSuccess:(BOOL)success) {
  [self.mbarkPurchaseActionHandler finishWithSuccess:success];
}

/// Removes a purchase action handler
RCT_EXPORT_METHOD(unregisterPurchaseEvent) {
  if (self.mbarkPurchaseActionHandler) {
  [Mbark removePurchaseActionHandlerForId: self.mbarkPurchaseActionHandler.id];
    self.mbarkPurchaseActionHandler = nil;
  }
}

- (nullable MbarkEventData*)eventDataFromDictionary:(nullable NSDictionary*)dictionary {
  MbarkEventData* eventData = nil;
  if (dictionary[@"name"] != nil && dictionary[@"value"] != nil) {
    eventData = [[MbarkEventData alloc] initWithName:dictionary[@"name"]
                                               value:dictionary[@"value"]];
  }
  return eventData;
}

@end
