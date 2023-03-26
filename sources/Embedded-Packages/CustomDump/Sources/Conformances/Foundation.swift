import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// NB: Xcode 13 does not include macOS 12 SDK
// NB: Swift 5.5 does not include AttributedString on other platforms (yet)
#if compiler(>=5.5) && !targetEnvironment(macCatalyst) && (os(iOS) || os(tvOS) || os(watchOS))
  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension AttributedString: CustomDumpRepresentable {
    var customDumpValue: Any {
      NSAttributedString(self).string
    }
  }
#endif

extension Calendar: CustomDumpReflectable {
  var customDumpMirror: Mirror {
    .init(
      self,
      children: [
        "identifier": self.identifier,
        "locale": self.locale as Any,
        "timeZone": self.timeZone,
        "firstWeekday": self.firstWeekday,
        "minimumDaysInFirstWeek": self.minimumDaysInFirstWeek,
      ],
      displayStyle: .struct
    )
  }
}

#if !os(WASI)
  extension Data: CustomDumpStringConvertible {
    var customDumpDescription: String {
      "Data(\(Self.formatter.string(fromByteCount: .init(self.count))))"
    }

    private static let formatter: ByteCountFormatter = {
      let formatter = ByteCountFormatter()
      formatter.allowedUnits = .useBytes
      return formatter
    }()
  }
#endif

#if !os(WASI)
  extension Date: CustomDumpStringConvertible {
    var customDumpDescription: String {
      "Date(\(Self.formatter.string(from: self)))"
    }

    private static let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
      formatter.timeZone = TimeZone(secondsFromGMT: 0)!
      return formatter
    }()
  }
#endif

extension Decimal: CustomDumpStringConvertible {
  var customDumpDescription: String {
    self.description
  }
}

extension Locale: CustomDumpStringConvertible {
  var customDumpDescription: String {
    "Locale(\(self.identifier))"
  }
}

extension NSAttributedString: CustomDumpRepresentable {
  var customDumpValue: Any {
    self.string
  }
}

extension NSCalendar: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as Calendar
  }
}

extension NSData: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as Data
  }
}

extension NSDate: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as Date
  }
}

extension NSError: CustomDumpReflectable {
  var customDumpMirror: Mirror {
    let swiftError = self as Error
    guard type(of: swiftError) is NSError.Type else {
      return Mirror(reflecting: swiftError)
    }
    return Mirror(
      self,
      children: [
        "domain": self.domain,
        "code": self.code,
        "userInfo": self.userInfo,
      ],
      displayStyle: .class
    )
  }
}

// NB: `NSException` in unavailable on Linux
#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
  extension NSException: CustomDumpReflectable {
    var customDumpMirror: Mirror {
      .init(
        self,
        children: [
          "name": self.name,
          "reason": self.reason as Any,
          "userInfo": self.userInfo as Any,
        ],
        displayStyle: .class
      )
    }
  }
#endif

extension NSExceptionName: CustomDumpStringConvertible {
  var customDumpDescription: String {
    self.rawValue
  }
}

// NB: `NSExpression` in unavailable on Linux
#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
  extension NSExpression: CustomDumpStringConvertible {
    var customDumpDescription: String {
      self.debugDescription
    }
  }
#endif

extension NSIndexPath: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as IndexPath
  }
}

extension NSIndexSet: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as IndexSet
  }
}

extension NSLocale: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as Locale
  }
}

@available(iOS 10, macOS 10.12, tvOS 10, watchOS 3, *)
extension NSMeasurement: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as Measurement
  }
}

#if !os(WASI)
  extension NSNotification: CustomDumpRepresentable {
    var customDumpValue: Any {
      self as Notification
    }
  }
#endif

extension NSOrderedSet: CustomDumpReflectable {
  var customDumpMirror: Mirror {
    .init(
      self,
      unlabeledChildren: self.array,
      displayStyle: .collection
    )
  }
}

extension NSPredicate: CustomDumpStringConvertible {
  var customDumpDescription: String {
    self.debugDescription
  }
}

extension NSRange: CustomDumpRepresentable {
  var customDumpValue: Any {
    Range(self) as Any
  }
}

extension NSString: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as String
  }
}

extension NSTimeZone: CustomDumpRepresentable {
  var customDumpValue: Any {
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
      return self as TimeZone
    #else
      // NB: Cannot cast directly to `TimeZone` on Linux
      return TimeZone(identifier: self.name) as Any
    #endif
  }
}

extension NSURL: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as URL
  }
}

extension NSURLComponents: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as URLComponents
  }
}

extension NSURLQueryItem: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as URLQueryItem
  }
}

#if !os(WASI)
  extension NSURLRequest: CustomDumpRepresentable {
    var customDumpValue: Any {
      self as URLRequest
    }
  }
#endif

extension NSUUID: CustomDumpRepresentable {
  var customDumpValue: Any {
    self as UUID
  }
}

extension NSValue: CustomDumpStringConvertible {
  var customDumpDescription: String {
    self.debugDescription
  }
}

extension TimeZone: CustomDumpReflectable {
  var customDumpMirror: Mirror {
    .init(
      self,
      children: [
        "identifier": self.identifier,
        "abbreviation": self.abbreviation() as Any,
        "secondsFromGMT": self.secondsFromGMT(),
        "isDaylightSavingTime": self.isDaylightSavingTime(),
      ],
      displayStyle: .struct
    )
  }
}

extension URL: CustomDumpStringConvertible {
  var customDumpDescription: String {
    "URL(\(self.absoluteString))"
  }
}

#if !os(WASI)
  extension URLRequest.NetworkServiceType: CustomDumpStringConvertible {
    var customDumpDescription: String {
      switch self { #if canImport(FoundationNetworking)
        case .background:
          return "URLRequest.NetworkServiceType.background"
        case .default:
          return "URLRequest.NetworkServiceType.default"
        case .networkServiceTypeCallSignaling:
          return "URLRequest.NetworkServiceType.networkServiceTypeCallSignaling"
        case .video:
          return "URLRequest.NetworkServiceType.video"
        case .voice:
          return "URLRequest.NetworkServiceType.voice"
        case .voip:
          return "URLRequest.NetworkServiceType.voip"
      #else
        case .avStreaming:
          return "URLRequest.NetworkServiceType.avStreaming"
        case .background:
          return "URLRequest.NetworkServiceType.background"
        case .callSignaling:
          return "URLRequest.NetworkServiceType.callSignaling"
        case .default:
          return "URLRequest.NetworkServiceType.default"
        case .responsiveAV:
          return "URLRequest.NetworkServiceType.responsiveAV"
        case .responsiveData:
          return "URLRequest.NetworkServiceType.responsiveData"
        case .video:
          return "URLRequest.NetworkServiceType.video"
        case .voice:
          return "URLRequest.NetworkServiceType.voice"
        case .voip:
          return "URLRequest.NetworkServiceType.voip"
        @unknown default:
          return "URLRequest.NetworkServiceType.(@unknown default, rawValue: \(self.rawValue))"
      #endif
      }
    }
  }
#endif

extension UUID: CustomDumpStringConvertible {
  var customDumpDescription: String {
    "UUID(\(self.uuidString))"
  }
}
