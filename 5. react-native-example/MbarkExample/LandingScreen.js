
// An example implementation of the Mbark SDK in React Native
// MbarkButton.onPress kicks off event tracking on Mbark screens and 
// presents an onboarding flow, starting with screenId that is provided.

'use strict';

import React, { Component } from 'react';
import {
    SafeAreaView,
    StyleSheet,
    Text,
    useColorScheme,
    Image,
    Button,
    View,
    NativeEventEmitter, 
} from 'react-native';

import {
    Colors,
} from 'react-native/Libraries/NewAppScreen';

import Mbark, { MbarkEventType } from './Mbark';
import MbarkView from './MbarkView';

const Section = ({children, title}) => {
    const isDarkMode = useColorScheme() === 'dark';
    return (
      <View style={styles.sectionContainer}>
        <Text
          style={[
            styles.sectionTitle,
            {
              color: isDarkMode ? Colors.white : Colors.black,
            },
          ]}>
          {title}
        </Text>
        <Text
          style={[
            styles.sectionDescription,
            {
              color: isDarkMode ? Colors.light : Colors.dark,
            },
          ]}>
          {children}
        </Text>
      </View>
    );
  };

const MbarkButton = () => {
    const onPress = () => {
        Mbark.trackFlowStart();
        Mbark.presentOnboardingWithStartingViewId("screen-000");
    };

    return (
        <Button
        title="Launch onboarding flow"
        color="#841584"
        onPress={onPress}
        />
    );
};

export default class LandingScreen extends Component {

    mbarkEmitter = new NativeEventEmitter(Mbark);

    subscription;

    componentDidMount() {
        // To access Mbark action handlers we add a listener to `mbarkEvent`
        // `MbarkActionHandler` calls will be transcribed to an event payload
        // which can be responded to based on a registered `eventId`.
        this.subscription = this.mbarkEmitter.addListener('mbarkEvent', (event) => { 
            console.log(event.id) 
            Mbark.markEventCompleteForEventId(event.id, true);
        });
        // We register the `eventId`s we will handle. These correspond to Tieback IDs
        // in ScreenBuilder. This allows ScreenBuilder users an opportunity to remotely
        // assign existing functionality to Mbark's UI.
        Mbark.registerEventForId("sign_in");
    }

    componentWillUnmount() {
        this.subscription.remove();
        // We can signal to the Mbark SDK that we are no longer interested in handling
        // events for given `eventId`s.
        Mbark.unregisterEventForId("sign_in");
    }

    render() {
      return (
        <SafeAreaView style={{ backgroundColor: Colors.white }}>
          <View
            style={{
                backgroundColor: Colors.white,
                alignItems: 'center',
            }}>
            <Section title="Mbark Example">
              welcome to mbark
            </Section>
            <Image source={require('./Resources/logo.png')} style={styles.image}/>
            <MbarkButton/>
          </View>
        </SafeAreaView>
      );
    };
  };

const styles = StyleSheet.create({
    sectionContainer: {
        marginTop: 32,
        paddingHorizontal: 24,
    },
    sectionTitle: {
        fontSize: 24,
        fontWeight: '600',
        textAlign: 'center',
    },
    sectionDescription: {
        marginTop: 8,
        fontSize: 18,
        fontWeight: '400',
        textAlign: 'center',
    },
    highlight: {
        fontWeight: '700',
    },
    image: {
        width: 200,
        height: 170, 
        margin: 20
    },
});