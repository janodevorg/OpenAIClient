extension Character: CustomDumpRepresentable {
  var customDumpValue: Any {
    String(self)
  }
}

extension ObjectIdentifier: CustomDumpStringConvertible {
  var customDumpDescription: String {
    self.debugDescription
      .replacingOccurrences(of: "0x0*", with: "0x", options: .regularExpression)
  }
}

extension StaticString: CustomDumpRepresentable {
  var customDumpValue: Any {
    "\(self)"
  }
}

extension UnicodeScalar: CustomDumpRepresentable {
  var customDumpValue: Any {
    String(self)
  }
}

extension AnyHashable: CustomDumpRepresentable {
  var customDumpValue: Any {
    base
  }
}
