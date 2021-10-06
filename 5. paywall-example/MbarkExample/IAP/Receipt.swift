//
//  Receipt.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-10-05.
//

import UIKit

enum ReceiptStatus: String {
  case validationSuccess = "Valid receipt."
  case noReceiptPresent = "Receipt not found."
  case unknownFailure = "Uexpected failure occurred."
  case unknownReceiptFormat = "The receipt is not PKCS7."
  case invalidPKCS7Signature = "Invalid Signature."
  case invalidPKCS7Type = "Invalid Type."
  case invalidAppleRootCertificate = "Apple root certificate not found."
  case failedAppleSignature = "Receipt not signed by Apple."
  case unexpectedASN1Type = "Unexpected Type."
  case missingComponent = "Expected component not found."
  case invalidBundleIdentifier = "Receipt bundle id does not match app bundle id."
  case invalidVersionIdentifier = "Receipt version id does not match app version."
  case invalidHash = "Failed hash check."
  case invalidExpired = "Receipt expired."
}

class Receipt {

  let certificate = "StoreKitTestCertificate"

  var receiptStatus: ReceiptStatus?
  var bundleIdString: String?
  var bundleVersionString: String?
  var bundleIdData: Data?
  var hashData: Data?
  var opaqueData: Data?
  var expirationDate: Date?
  var receiptCreationDate: Date?
  var originalAppVersion: String?
  var inAppReceipts: [InAppPurchaseReceipt] = []

  static func isReceiptPresent() -> Bool {
    if let receiptUrl = Bundle.main.appStoreReceiptURL,
       let canReach = try? receiptUrl.checkResourceIsReachable(),
       canReach {
      return true
    }
    return false
  }

  init() {
    guard let payload = loadReceipt() else { return }
    guard validateSigning(payload) else { return }

    readReceipt(payload)
    validateReceipt()
  }

  private func loadReceipt() -> UnsafeMutablePointer<PKCS7>? {
    guard let receiptUrl = Bundle.main.appStoreReceiptURL,
          let receiptData = try? Data(contentsOf: receiptUrl) else {
      receiptStatus = .noReceiptPresent
      return nil
    }
    let receiptBIO = BIO_new(BIO_s_mem())
    let receiptBytes: [UInt8] = .init(receiptData)
    BIO_write(receiptBIO, receiptBytes, Int32(receiptData.count))

    let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
    BIO_free(receiptBIO)

    guard receiptPKCS7 != nil else {
      receiptStatus = .unknownReceiptFormat
      return nil
    }

    guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
      receiptStatus = .invalidPKCS7Signature
      return nil
    }

    let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
    guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
      receiptStatus = .invalidPKCS7Type
      return nil
    }
    return receiptPKCS7
  }

  private func validateSigning(_ receipt: UnsafeMutablePointer<PKCS7>?) -> Bool {
    guard let rootCertUrl = Bundle.main.url(forResource: certificate, withExtension: "cer"),
          let rootCertData = try? Data(contentsOf: rootCertUrl) else {
      receiptStatus = .invalidAppleRootCertificate
      return false
    }

    let rootCertBio = BIO_new(BIO_s_mem())
    let rootCertBytes: [UInt8] = .init(rootCertData)
    BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
    let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
    BIO_free(rootCertBio)

    let store = X509_STORE_new()
    X509_STORE_add_cert(store, rootCertX509)

    OPENSSL_init_crypto(UInt64(OPENSSL_INIT_ADD_ALL_DIGESTS), nil)

    let verificationResult = PKCS7_verify(receipt, nil, store, nil, nil, PKCS7_NOCHAIN)

    guard verificationResult == 1  else {
      receiptStatus = .failedAppleSignature
      return false
    }

    return true
  }

  private func readReceipt(_ receiptPKCS7: UnsafeMutablePointer<PKCS7>?) {
    let receiptSign = receiptPKCS7?.pointee.d.sign
    let octets = receiptSign?.pointee.contents.pointee.d.data
    var ptr = UnsafePointer(octets?.pointee.data)

    let end = ptr!.advanced(by: Int(octets!.pointee.length))

    var type: Int32 = 0
    var xclass: Int32 = 0
    var length: Int = 0

    ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
    guard type == V_ASN1_SET else {
      receiptStatus = .unexpectedASN1Type
      return
    }

    while ptr! < end {
      ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
      guard type == V_ASN1_SEQUENCE else {
        receiptStatus = .unexpectedASN1Type
        return
      }

      guard let attributeType = readASN1Integer(ptr: &ptr, maxLength: length) else {
        receiptStatus = .unexpectedASN1Type
        return
      }

      guard readASN1Integer(ptr: &ptr, maxLength: ptr!.distance(to: end)) != nil else {
        receiptStatus = .unexpectedASN1Type
        return
      }

      ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
      guard type == V_ASN1_OCTET_STRING else {
        receiptStatus = .unexpectedASN1Type
        return
      }

      switch attributeType {
      case 2:
        var stringStartPtr = ptr
        bundleIdString = readASN1String(ptr: &stringStartPtr, maxLength: length)
        bundleIdData = readASN1Data(ptr: ptr!, length: length)

      case 3:
        var stringStartPtr = ptr
        bundleVersionString = readASN1String(ptr: &stringStartPtr, maxLength: length)

      case 4:
        let dataStartPtr = ptr!
        opaqueData = readASN1Data(ptr: dataStartPtr, length: length)

      case 5:
        let dataStartPtr = ptr!
        hashData = readASN1Data(ptr: dataStartPtr, length: length)

      case 12:
        var dateStartPtr = ptr
        receiptCreationDate = readASN1Date(ptr: &dateStartPtr, maxLength: length)

      case 17:
        var iapStartPtr = ptr
        let parsedReceipt = InAppPurchaseReceipt(with: &iapStartPtr, payloadLength: length)
        if let newReceipt = parsedReceipt {
          inAppReceipts.append(newReceipt)
        }

      case 19:
        var stringStartPtr = ptr
        originalAppVersion = readASN1String(ptr: &stringStartPtr, maxLength: length)

      case 21:
        var dateStartPtr = ptr
        expirationDate = readASN1Date(ptr: &dateStartPtr, maxLength: length)

      default:
        print("Cannot process attribute type: \(attributeType)")
      }

      ptr = ptr!.advanced(by: length)
    }
  }

  private func validateReceipt() {
    guard let idString = bundleIdString,
          let version = bundleVersionString,
          opaqueData != nil,
          let hash = hashData else {
      receiptStatus = .missingComponent
      return
    }

    guard let appBundleId = Bundle.main.bundleIdentifier else {
      receiptStatus = .unknownFailure
      return
    }

    guard idString == appBundleId else {
      receiptStatus = .invalidBundleIdentifier
      return
    }

    guard let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
      receiptStatus = .unknownFailure
      return
    }

    guard version == appVersionString else {
      receiptStatus = .invalidVersionIdentifier
      return
    }

    let guidHash = computeHash()

    guard hash == guidHash else {
      receiptStatus = .invalidHash
      return
    }

    let currentDate = Date()

    if let expirationDate = expirationDate {
      if expirationDate < currentDate {
        receiptStatus = .invalidExpired
        return
      }
    }

    receiptStatus = .validationSuccess
  }

  private func getDeviceIdentifier() -> Data {
    let device = UIDevice.current
    
    var uuid = device.identifierForVendor!.uuid
    let addr = withUnsafePointer(to: &uuid) { ptr -> UnsafeRawPointer in
      UnsafeRawPointer(ptr)
    }
    let data = Data(bytes: addr, count: 16)
    return data
  }

  private func computeHash() -> Data {
    let identifierData = getDeviceIdentifier()
    var ctx = SHA_CTX()
    SHA1_Init(&ctx)

    let identifierBytes: [UInt8] = .init(identifierData)
    SHA1_Update(&ctx, identifierBytes, identifierData.count)

    if let opaqueData = opaqueData {
      let opaqueBytes: [UInt8] = .init(opaqueData)
      SHA1_Update(&ctx, opaqueBytes, opaqueData.count)
    }

    if let bundleIdData = bundleIdData {
      let bundleBytes: [UInt8] = .init(bundleIdData)
      SHA1_Update(&ctx, bundleBytes, bundleIdData.count)
    }

    var hash: [UInt8] = .init(repeating: 0, count: 20)
    SHA1_Final(&hash, &ctx)
    return Data(bytes: hash, count: 20)
  }
}
