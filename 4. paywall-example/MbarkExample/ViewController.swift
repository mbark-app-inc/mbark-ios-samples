//
//  ViewController.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-09-29.
//

import UIKit
import Mbark

class ViewController: UIViewController {

  // MARK: - Identifiers

  let startingViewId = "screen-000"

  enum TiebackId: String, CaseIterable {
    case terms = "TERMS"
    case purchase
  }

  let store = PurchaseManager(withProductIds: ["co.mbark.premium.monthly"])

  typealias TiebackCompletion = (() -> Void)?

  // MARK: - State

  /// Handles terms interactions
  var termsHandler: MbarkActionHandler?

  /// Handles purchase interactions
  var purchaseHandler: MbarkPurchaseActionHandler?

  /// Keeps track of the currently displayed view controller. This is used to present a `UIAlertController`.
  var currentViewController: UIViewController?

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize the Mbark SDK.
    // Mbark.initializeSDK()
    Mbark.initializeSDK(instanceName: "paywall", remoteConfigId: "demo-3-paywall", developmentAPIKey: "API_KEY")

    // Add a tiebacks
    addTiebacks()

    // Add notification observers
    addObservers()

    // Load products
    store.requestProducts { success, products in
      DispatchQueue.main.async {
        print("success: \(success)")
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    currentViewController = self
  }

  /// Launch the Mbark user flow
  @IBAction func launchMbarkFlow(_ sender: Any) {
    // Track analytics on the Mbark flow
    Mbark.trackFlowStart()
    guard let userFlow = Mbark.userFlow(startingViewId: startingViewId) else {
      // The flow will automatically end analytics tracking once it completes.
      // In the event that we can't load a specified flow, we can manually end it ourselves.
      Mbark.trackFlowEnd()
      return
    }
    // Set the presentation mode to fullscreen
    userFlow.modalPresentationStyle = .fullScreen
    // Present the user-flow.
    present(userFlow, animated: true) { [weak self] in
      self?.currentViewController = userFlow
    }
  }

  private func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
                                           name: .PurchaseManagerPurchaseNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(handleErrorNotification(_:)),
                                           name: .PurchaseManagerErrorNotification,
                                           object: nil)
  }

  // MARK: - Tiebacks

  /// Registers a tieback action handler with the mbark SDK. We pass in a tiebackId (which gets set on the web in the
  /// Screen Builder, and a handler closure.
  private func addTiebacks() {
    addTermsTieback()
    addPurchaseTieback()
  }

  /// Adds a tieback to handle a request to see Terms & Conditions
  private func addTermsTieback() {
    termsHandler = MbarkActionHandler(id: TiebackId.terms.rawValue, handler: { [weak self] in
      self?.showAlert(withTitle: "Terms & Conditions Tapped Integration point with your legal terms & conditions") {
        self?.termsHandler?.finish(success: true)
      }
    })
    Mbark.addActionHandler(termsHandler!)
  }

  /// Adds a tieback to handle a IAP request from the mbark paywall
  private func addPurchaseTieback() {
    purchaseHandler = MbarkPurchaseActionHandler(id: TiebackId.purchase.rawValue, handler: { [weak self] sku in
      guard let self = self else { return }
      guard !self.store.hasPurchased(sku) else {
        // Show an alert indicating the transaction completed successfully.
        self.showAlert(withTitle: "Purchase already made."){
          self.purchaseHandler?.finish(success: true)
        }
        return
      }
      self.store.purchase(productId: sku)
    })
    Mbark.addPurchaseActionHandler(self.purchaseHandler!)
  }

  // MARK: - Helpers

  /// Handles a 'successful transaction' notification from the `PurchaseManager`
  @objc func handlePurchaseNotification(_ notification: Notification) {
    guard let productId = notification.object as? String else { return }
    showAlert(withTitle: "Purchase successful for: \(productId)") { [weak self] in
      self?.purchaseHandler?.finish(success: true)
    }
  }

  /// Handles any errors in the transaction flow
  @objc func handleErrorNotification(_ notification: Notification) {
    showAlert(withTitle: "Purchase unsuccessful.") { [weak self] in
      self?.purchaseHandler?.finish(success: false)
    }
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
