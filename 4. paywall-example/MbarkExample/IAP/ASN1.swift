//
//  ASN1.swift
//  MbarkExample
//
//  Created by Nate de Jager on 2021-10-05.
//

import Foundation

func readASN1Data(ptr: UnsafePointer<UInt8>, length: Int) -> Data {
  return Data(bytes: ptr, count: length)
}

func readASN1Integer(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Int? {
  var type: Int32 = 0
  var xclass: Int32 = 0
  var length: Int = 0

  ASN1_get_object(&ptr, &length, &type, &xclass, maxLength)
  guard type == V_ASN1_INTEGER else {
    return nil
  }
  let integerObject = c2i_ASN1_INTEGER(nil, &ptr, length)
  let intValue = ASN1_INTEGER_get(integerObject)
  ASN1_INTEGER_free(integerObject)

  return intValue
}

func readASN1String(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> String? {
  var strClass: Int32 = 0
  var strLength = 0
  var strType: Int32 = 0

  var strPointer = ptr
  ASN1_get_object(&strPointer, &strLength, &strType, &strClass, maxLength)
  if strType == V_ASN1_UTF8STRING {
    let pointer = UnsafeMutableRawPointer(mutating: strPointer!)
    let utfString = String(bytesNoCopy: pointer, length: strLength, encoding: .utf8, freeWhenDone: false)
    return utfString
  }

  if strType == V_ASN1_IA5STRING {
    let pointer = UnsafeMutablePointer(mutating: strPointer!)
    let ia5String = String(bytesNoCopy: pointer, length: strLength, encoding: .ascii, freeWhenDone: false)
    return ia5String
  }
  return nil
}

func readASN1Date(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Date? {
  var strXclass: Int32 = 0
  var strLength = 0
  var strType: Int32 = 0

  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
  formatter.timeZone = TimeZone(abbreviation: "GMT")

  var strPointer = ptr
  ASN1_get_object(&strPointer, &strLength, &strType, &strXclass, maxLength)
  guard strType == V_ASN1_IA5STRING else {
    return nil
  }

  let ptr = UnsafeMutableRawPointer(mutating: strPointer!)
  if let dateString = String(bytesNoCopy: ptr, length: strLength, encoding: .ascii, freeWhenDone: false) {
    return formatter.date(from: dateString)
  }

  return nil
}
