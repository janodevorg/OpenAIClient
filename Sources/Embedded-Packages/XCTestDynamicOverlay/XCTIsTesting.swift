import Foundation

#if !os(WASI)
  let _XCTIsTesting: Bool = {
    ProcessInfo.processInfo.environment.keys.contains("XCTestBundlePath")
      || ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath")
      || ProcessInfo.processInfo.environment.keys.contains("XCTestSessionIdentifier")
      || (ProcessInfo.processInfo.arguments.first
        .flatMap(URL.init(fileURLWithPath:))
        .map { $0.lastPathComponent == "xctest" || $0.pathExtension == "xctest" }
        ?? false)
      || XCTCurrentTestCase != nil
  }()
#else
  let _XCTIsTesting = false
#endif
