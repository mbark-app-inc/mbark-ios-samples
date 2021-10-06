//
//  ViewController.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-29.
//

import UIKit
import Mbark

class ViewController: UIViewController {

  let startingViewId = "screen-002"

  /// enum used to manage tieback Ids
  enum TiebackId: String, CaseIterable {
    case terms = "TERMS"
    case privacy = "PRIVACY"
  }

  typealias TiebackCompletion = (() -> Void)?

  /// A handler used to respond to a terms tieback call.
  var termsTieback: MbarkActionHandler?

  /// A handler used to respond to a privacy tieback call.
  var privacyTieback: MbarkActionHandler?

  /// Keeps track of the currently displayed view controller. This is used to present a `UIAlertController`.
  var currentViewController: UIViewController?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize the Mbark SDK.
    Mbark.initializeSDK()

    // Add a tiebacks
    addTiebacks()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    currentViewController = self
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

    // Update the presentation modal style to be fullscreen
    userFlow.modalPresentationStyle = .fullScreen

    // Present the user-flow.
    present(userFlow, animated: true) { [weak self] in
      self?.currentViewController = userFlow
    }
  }

  /// Registers a tieback action handler with the mbark SDK. We pass in a tiebackId (which gets set
  /// on the web in the Screen Builder, and a handler closure.
  private func addTiebacks() {
    addTermsTieback()
    addPrivacyTieback()
  }

  private func addTermsTieback() {
    termsTieback = MbarkActionHandler(id: TiebackId.terms.rawValue, handler: { [weak self] in
      self?.showAlert(withTitle: "Display Terms & Conditions") {
        // Once our tieback is complete we let the handler know. This allows us to chain actions
        // together to create complex action flows, passing the flow between a host app and the
        // mbark SDK.
        self?.termsTieback?.finish(success: true)
      }
    })
    Mbark.addActionHandler(termsTieback!)
  }

  private func addPrivacyTieback() {
    privacyTieback = MbarkActionHandler(id: TiebackId.privacy.rawValue, handler: { [weak self] in
      self?.showAlert(withTitle: "Display Privacy Policy") {
        // Once our tieback is complete we let the handler know. This allows us to chain actions
        // together to create complex action flows, passing the flow between a host app and the
        // mbark SDK.
        self?.privacyTieback?.finish(success: true)
      }
    })
    Mbark.addActionHandler(privacyTieback!)
  }


  /// Displays a simple alert, calling a completion handler on close, if one is passed in.
  private func showAlert(withTitle title: String, completion: TiebackCompletion = nil) {
    let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: { _ in
      completion?()
    }))
    currentViewController?.present(alert, animated: true)
  }
}
