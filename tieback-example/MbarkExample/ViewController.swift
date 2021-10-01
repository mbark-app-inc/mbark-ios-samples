//
//  ViewController.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-29.
//

import UIKit
import Mbark

class ViewController: UIViewController {

  let startingViewId = "screen-001"
  let tiebackId = "example_tieback"

  typealias TiebackCompletion = (() -> Void)?

  // A handler used to respond to a tieback call.
  var tiebackHandler: MbarkActionHandler?

  // Keeps track of the currently displayed view controller. This is used to present a
  // `UIAlertController`.
  var currentViewController: UIViewController?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize the Mbark SDK.
    Mbark.initializeSDK()

    // Add a tieback handler
    addTiebackHandler()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    currentViewController = self
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
    present(userFlow, animated: true) { [weak self] in
      self?.currentViewController = userFlow
    }
  }

  // Registers a tieback action handler with the mbark SDK. We pass in a tiebackId (which gets set
  // on the web in the Screen Builder, and a handler closure.
  private func addTiebackHandler() {
    tiebackHandler = MbarkActionHandler(id: tiebackId, handler: { [weak self] in
      self?.showAlert(withTitle: "Tieback successfully called!") {
        // Once our tieback is complete we let the handler know. This allows us to chain actions
        // together to create complex action flows, seamlessly passing the flow between a host app
        // and the mbark SDK.
        self?.tiebackHandler?.finish(success: true)
      }
    })
    Mbark.addActionHandler(tiebackHandler!)
  }

  // Displays a simple alert, calling a completion handler on close, if one is passed in.
  private func showAlert(withTitle title: String, completion: TiebackCompletion = nil) {
    let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: { _ in
      completion?()
    }))
    currentViewController?.present(alert, animated: true)
  }
}
