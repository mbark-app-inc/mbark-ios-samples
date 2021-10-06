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

    /// Initialize the Mbark SDK.
    // Mbark.initializeSDK()
    Mbark.initializeSDK(instanceName: "intro", remoteConfigId: "demo-5-notice", developmentAPIKey: "API_KEY")
  }

  @IBAction func launchMbarkFlow(_ sender: Any) {
    // Track analytics on the Mbark flow
    Mbark.trackFlowStart()
    guard let userFlow = Mbark.userFlow(startingViewId: startingViewId) else {
      // The flow will automatically end analytics tracking once it completes.
      // In the event that we can't load a specified flow, we can manually end it ourselves.
      Mbark.trackFlowEnd()
      return
    }
    // Set the presentation style to fullscreen
    userFlow.modalPresentationStyle = .fullScreen
    
    // Present the user-flow.
    present(userFlow, animated: true)
  }
}
