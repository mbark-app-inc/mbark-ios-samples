import { NativeModules, View } from 'react-native';

const { Mbark } = NativeModules;

interface MbarkInterface {
    // Initialize
    initialize(): void;
    initializeWithInstanceName(instanceName: string, configId: string, apiKey: string): void;

    // SDK active state
    isActive(resolve: Promise<boolean>, reject: Promise<boolean>): void;

    // Flow boundary events
    trackFlowStart(): void
    trackFlowEnd(): void
    
    // Manual event tracking
    trackEvent(eventType: number, step?: string, component?: string, data?: MbarkEventData): void
    trackOnce(eventType: number, step?: string, component?: string, data?: MbarkEventData): void
    
    // Step view event tracking
    trackStepView(step: string, data?: MbarkEventData): void
    
    // Authentication event tracking
    trackAuthenticationForNewUser(): void
    trackAuthenticationForExistingUser(): void

    // Permissions event tracking
    trackAcceptWithStep(step?: string, component?: string, shouldTrackOnce?: boolean): void
    trackRejectWithStep(step?: string, component?: string, shouldTrackOnce?: boolean): void

    // Interaction event tracking
    trackTapWithStep(step?: string, component?: string, data?: MbarkEventData): void
    trackInputWithStep(step?: string, component?: string, data?: MbarkEventData): void

    // App loading event tracking
    trackAppLoading(): void

    // UI rendering
    presentOnboardingWithStartingViewId(viewId: string): void;
    mbarkViewControllerForViewId(iewId: string, resolver: Promise<View>, rejector: Promise<boolean>): void

    // Action handlers
    registerEventForId(eventId: string) : void;
    markEventCompleteForEventId(eventId: string, success: boolean): void
    unregisterEventForId(eventId: String): void
    registerPurchaseEventForId(eventId: string) : void
    markPurchaseEventCompleteWithSuccess(success: boolean): void
    unregisterPurchaseEvent(): void
}

export default Mbark as MbarkInterface;

export const MbarkEventType = {
    Accept: 0,
    Authenticate: 1,
    Background: 2,
    Foreground: 3,
    FlowStart: 4,
    FlowEnd: 5,
    Input: 6,
    LongPress: 7,
    Reject: 8,
    SwipeLeft: 9,
    SwipeRight: 10,
    Tap: 11,
    View: 12,
} as const;


export type MbarkEventData = {
    name: string;
    value: string;
};
