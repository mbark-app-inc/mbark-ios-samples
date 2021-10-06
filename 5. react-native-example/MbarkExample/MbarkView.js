
// Provides a wrapper around `MbarkViewController` allowing us to embed 
// single views inside existing UI.

'use strict';

import React, { Component } from 'react'
import PropTypes from 'prop-types';
import { requireNativeComponent } from 'react-native'

type Props = {
  config: { screenId: string },
  style?: Object
}

export default class MbarkView extends Component<any, Props, any> {
  render() {
    return <MbarkControllerView style={this.props.style} {...this.props} />
  }
}

MbarkView.propTypes = {
    config: PropTypes.shape({ screenId: PropTypes.string }).isRequired
}

const MbarkControllerView = requireNativeComponent('MbarkControllerView', MbarkView)
