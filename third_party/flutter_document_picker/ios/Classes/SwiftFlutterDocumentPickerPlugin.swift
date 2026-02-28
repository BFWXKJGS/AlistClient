import Flutter
import UIKit
    
public class SwiftFlutterDocumentPickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_document_picker", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterDocumentPickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    let delegate = SwiftFlutterDocumentPickerDelegate()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickDocument":
            let params = parseArgs(call, result: result)

            delegate.pickDocument(params, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func parseArgs(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> FlutterDocumentPickerParams? {
        guard let args = call.arguments as? [String: Any?] else {
            return nil
        }

        return FlutterDocumentPickerParams(
                allowedUtiTypes: args[FlutterDocumentPickerParams.ALLOWED_UTI_TYPES]  as? [String],
                allowedFileExtensions: args[FlutterDocumentPickerParams.ALLOWED_FILE_EXTENSIONS]  as? [String],
                invalidFileNameSymbols: args[FlutterDocumentPickerParams.INVALID_FILENAME_SYMBOLS]  as? [String],
                isMultipleSelection: args[FlutterDocumentPickerParams.IS_MULTIPLE_SELECTION]  as? Bool
            )
    }
}

struct FlutterDocumentPickerParams {
    static let ALLOWED_UTI_TYPES = "allowedUtiTypes"
    static let ALLOWED_FILE_EXTENSIONS = "allowedFileExtensions"
    static let INVALID_FILENAME_SYMBOLS = "invalidFileNameSymbols"
    static let IS_MULTIPLE_SELECTION = "isMultipleSelection"
    let allowedUtiTypes: [String]?
    let allowedFileExtensions: [String]?
    let invalidFileNameSymbols: [String]?
    let isMultipleSelection: Bool?
}
