//
//  InAppPurchaseReceipt.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-10-05.
//

import Foundation

struct InAppPurchaseReceipt {
  var quantity: Int?
  var productId: String?
  var transactionId: String?
  var originalTransactionId: String?
  var purchaseDate: Date?
  var originalPurchaseDate: Date?
  var cancellationDate: String?
  var subscriptionExpirationDate: Date?
  var subscriptionIntroductoryPricePeriod: Int?
  var subscriptionCancellationDate: Date?
  var webOrderLineId: Int?

  init?(with pointer: inout UnsafePointer<UInt8>?, payloadLength: Int) {
    let endPointer = pointer!.advanced(by: payloadLength)
    var type: Int32 = 0
    var xclass: Int32 = 0
    var length = 0

    ASN1_get_object(&pointer, &length, &type, &xclass, payloadLength)
    guard type == V_ASN1_SET else {
      return nil
    }

    while pointer! < endPointer {
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_SEQUENCE else {
        return nil
      }
      guard let attributeType = readASN1Integer(ptr: &pointer, maxLength: pointer!.distance(to: endPointer))
        else {
          return nil
      }
      guard readASN1Integer(ptr: &pointer, maxLength: pointer!.distance(to: endPointer)) != nil
        else {
          return nil
      }
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_OCTET_STRING else {
        return nil
      }

      switch attributeType {
      case 1701:
        var ptr = pointer
        quantity = readASN1Integer(ptr: &ptr, maxLength: length)
      case 1702:
        var ptr = pointer
        productId = readASN1String(ptr: &ptr, maxLength: length)
      case 1703:
        var ptr = pointer
        transactionId = readASN1String(ptr: &ptr, maxLength: length)
      case 1705:
        var ptr = pointer
        originalTransactionId = readASN1String(ptr: &ptr, maxLength: length)
      case 1704:
        var ptr = pointer
        purchaseDate = readASN1Date(ptr: &ptr, maxLength: length)
      case 1706:
        var ptr = pointer
        originalPurchaseDate = readASN1Date(ptr: &ptr, maxLength: length)
      case 1708:
        var ptr = pointer
        subscriptionExpirationDate = readASN1Date(ptr: &ptr, maxLength: length)
      case 1712:
        var ptr = pointer
        cancellationDate = readASN1String(ptr: &ptr, maxLength: length)
      case 1711:
        var ptr = pointer
        webOrderLineId = readASN1Integer(ptr: &ptr, maxLength: length)
      default:
        break
      }
      pointer = pointer!.advanced(by: length)
    }
  }
}
