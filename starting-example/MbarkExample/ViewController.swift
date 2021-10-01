//
//  ViewController.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-29.
//

import UIKit
import Mbark

class ViewController: UIViewController {

  let startingViewId = "screen-000"

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize the Mbark SDK.
    Mbark.initializeSDK()
  }

  @IBAction func launchMbarkFlow(_ sender: Any) {
    // Track analytics on the Mbark flow
    Mbark.trackFlowStart()
    guard let userFlow = Mbark.onboarding(startingViewId: startingViewId, onLoaded: { _ in
      // If we need to perform any functions once the user-flow has rendered we can kick them off
      // in the `onLoaded` closure.
    }) else {
      // The flow will automatically end analytics tracking once it completes.
      // In the event that we can't load a specified flow, we can manually end it ourselves.
      Mbark.trackFlowEnd()
      return
    }
    // Present the user-flow.
    present(userFlow, animated: true)
  }
}
