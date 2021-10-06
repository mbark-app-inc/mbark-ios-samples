//
//  PurchaseManager.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-10-05.
//

import StoreKit

/// `PurchaseManager` is used to test basic IAP scenarios. It is not recommended to be used in production.

typealias OnProductsResponse = (Bool, [SKProduct]?) -> Void
typealias OnTransactionCompletion = (Bool) -> Void

extension Notification.Name {
  static let PurchaseManagerPurchaseNotification = Notification.Name("PurchaseManagerPurchaseNotification")
  static let PurchaseManagerErrorNotification = Notification.Name("PurchaseManagerErrorNotification")
}

class PurchaseManager: NSObject {

  // MARK: - State

  private let productIds: Set<String>

  private var purchasedProductIds: Set<String> = []
  private var currentProductsRequest: SKProductsRequest?
  private var onProductsResponse: OnProductsResponse?
  private var onPurchase: OnTransactionCompletion?

  private var products: [SKProduct]?

  // MARK: - Initialization

  init(withProductIds productIds: Set<String>) {
    self.productIds = productIds
    super.init()
    lookUpPurchases(withProductIds: productIds)
    SKPaymentQueue.default().add(self)
  }

  private func lookUpPurchases(withProductIds productIds: Set<String>) {
    productIds.forEach { productId in
      let isPurchased = UserDefaults.standard.bool(forKey: productId)
      if isPurchased {
        purchasedProductIds.insert(productId)
      }
    }
  }

  // MARK: - StoreKit

  func requestProducts(completionHandler: @escaping OnProductsResponse) {
    currentProductsRequest?.cancel()
    onProductsResponse = completionHandler

    currentProductsRequest = SKProductsRequest(productIdentifiers: productIds)

    guard let request = currentProductsRequest else { return }
    request.delegate = self
    request.start()
  }

  func purchase(productId: String) {
    let product = products?.first { product in
      product.productIdentifier == productId
    }

    guard let product = product else { return }
    purchase(product: product)
  }

  func purchase(product: SKProduct) {
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  func requestProductsAndPurchasae(productId: String,
                                          completionHandler: @escaping OnTransactionCompletion) {
    requestProducts { [self] success, products in
      guard success, let products = products else {
        return completionHandler(false)
      }

      let result = products.first { product in
        product.productIdentifier == productId
      }

      guard let product = result else {
        return completionHandler(false)
      }

      onPurchase = completionHandler

      let payment = SKPayment(product: product)
      SKPaymentQueue.default().add(payment)
    }
  }

  func purchase(productId: String, completionHandler: @escaping OnTransactionCompletion) {
    let result = products?.first { product in
      product.productIdentifier == productId
    }

    guard let product = result else {
      return completionHandler(false)
    }

    onPurchase = completionHandler

    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  func hasPurchased(_ productId: String) -> Bool {
    purchasedProductIds.contains(productId)
  }

  class func canMakePayments() -> Bool {
    SKPaymentQueue.canMakePayments()
  }

  func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }

  public func removePurchaseFor(productId: String?) {
    guard let identifier = productId else { return }

    purchasedProductIds.remove(identifier)
    UserDefaults.standard.set(false, forKey: identifier)
  }

  func receiptContains(_ productId: String) -> Bool {
    let receipt = Receipt()
    let purchased = receipt.inAppReceipts.filter { receipt -> Bool in
      return receipt.productId == productId
    }
    return !purchased.isEmpty
  }

  func checkSubscriptionExpiry(_ productId: String) -> Bool {
    let receipt = Receipt()

    let purchased = receipt.inAppReceipts.first { receipt in
      receipt.productId == productId
    }

    guard let expiryDate = purchased?.subscriptionExpirationDate else { return true }

    let expiryTimestamp: Double = expiryDate.timeIntervalSince1970
    let timestamp: Double = Date().timeIntervalSince1970

    if timestamp >= expiryTimestamp {
      purchasedProductIds.remove(productId)
      UserDefaults.standard.removeObject(forKey: productId)
      return true
    } else {
      return false
    }
  }

  static func price(_ product: SKProduct) -> String? {
    let formatter = NumberFormatter()
    formatter.formatterBehavior = .behavior10_4
    formatter.numberStyle = .currency
    formatter.locale = product.priceLocale
    return formatter.string(from: product.price)
  }
}

// MARK: - SKProductsRequestDelegate

extension PurchaseManager: SKProductsRequestDelegate, SKRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let products = response.products
    self.products = products
    onProductsResponse?(true, products)
    clearRequestAndHandler()

    for prod in products {
      print("Found product: \(prod.productIdentifier) \(prod.localizedTitle) \(prod.price.floatValue)")
    }
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    onProductsResponse?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    currentProductsRequest = nil
    onProductsResponse = nil
  }
}

// MARK: - SKPaymentTransactionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        purchased(transaction)
      case .failed:
        failed(transaction)
      case .restored:
        restored(transaction)
      case .deferred:
        break
      case .purchasing:
        break
      @unknown default:
        break
      }
    }
  }

  func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
    productIdentifiers.forEach { id in
      purchasedProductIds.remove(id)
      UserDefaults.standard.removeObject(forKey: id)
      postPurchaseNotificationFor(id: id)
    }
  }

  private func purchased(_ transaction: SKPaymentTransaction) {
    persistPurchase(id: transaction.payment.productIdentifier)
    postPurchaseNotificationFor(id: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func restored(_ transaction: SKPaymentTransaction) {
    guard let productId = transaction.original?.payment.productIdentifier else { return }
    persistPurchase(id: productId)
    postPurchaseNotificationFor(id: productId)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func failed(_ transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .PurchaseManagerErrorNotification,
                                      object: transaction.error?.localizedDescription ?? "")
    }
    onPurchase?(false)
  }

  private func postPurchaseNotificationFor(id: String?) {
    guard let id = id else { return }

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .PurchaseManagerPurchaseNotification, object: id)
    }
    onPurchase?(true)
  }

  private func persistPurchase(id: String?) {
    guard let id = id else { return }

    purchasedProductIds.insert(id)
    UserDefaults.standard.set(true, forKey: id)
  }
}
