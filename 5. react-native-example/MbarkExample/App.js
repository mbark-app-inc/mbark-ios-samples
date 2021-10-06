/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

'use strict';

import 'react-native-gesture-handler';

import PropTypes from 'prop-types';
import React, {Component} from 'react';

import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

import LandingScreen from './LandingScreen';
import MbarkView from './MbarkView';

const Stack = createStackNavigator();

export default class App extends Component {

  render() {
    return (
      // Example of mbark onboarding flow
      <NavigationContainer>
        <Stack.Navigator initialRouteName="Landing">
          <Stack.Screen name="Landing" component={ LandingScreen } />
        </Stack.Navigator>
      </NavigationContainer>
    );
  }
};