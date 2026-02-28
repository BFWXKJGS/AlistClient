//
//  SwiftFlutterDocumentPickerDelegate.swift
//  flutter_document_picker
//
//  Created by ts on 01/09/2018.
//

import Foundation
import UIKit

public class SwiftFlutterDocumentPickerDelegate: NSObject {
    fileprivate var flutterResult: FlutterResult?
    fileprivate var params: FlutterDocumentPickerParams?

    func pickDocument(_ params: FlutterDocumentPickerParams?, result: @escaping FlutterResult) {
        flutterResult = result
        self.params = params

        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError.init(code: "error",
                                     message: "Unable to get view controller!",
                                     details: nil)
            )
            return
        }

        var documentTypes = ["public.data"]

        if let allowedUtiTypes = params?.allowedUtiTypes {
            if !allowedUtiTypes.isEmpty {
                documentTypes = allowedUtiTypes
            }
        }

        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)

        documentPickerViewController.delegate = self
        if(params?.isMultipleSelection == true){
            documentPickerViewController.allowsMultipleSelection = true
        }

        viewController.present(documentPickerViewController, animated: true, completion: nil)
    }
}

extension SwiftFlutterDocumentPickerDelegate: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var arrayResult: [String?] = []
        for url in urls {
            let fileExtension = url.pathExtension

            if let allowedFileExtensions = params?.allowedFileExtensions {
                if !allowedFileExtensions.contains(where: { $0 == fileExtension }) {
                    flutterResult?(FlutterError.init(code: "extension_mismatch",
                                                     message: "Picked file extension mismatch!",
                                                     details: fileExtension))
                }
            }

            let fileName = sanitizeFileName(url.lastPathComponent)

            // Create file URL to temporary folder
            var tempUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            // Apend filename (name+extension) to URL
            tempUrl.appendPathComponent(fileName)
            do {
                // If file with same name exists remove it (replace file with new one)
                if FileManager.default.fileExists(atPath: tempUrl.path) {
                    try FileManager.default.removeItem(atPath: tempUrl.path)
                }
                // Move file from app_id-Inbox to tmp/filename
                try FileManager.default.moveItem(atPath: url.path, toPath: tempUrl.path)
                arrayResult.append(tempUrl.path)
               
            } catch {
                print(error.localizedDescription)
                arrayResult.append(nil)
          
            }
        }
        
        if(arrayResult.isEmpty){
            flutterResult?(nil)
        }
        else{
            flutterResult?(arrayResult)
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        flutterResult?(nil)
    }

    private func sanitizeFileName(_ fileName: String) -> String {
        var sanitizedFileName = fileName

        if let invalidSymbols = params?.invalidFileNameSymbols {
            invalidSymbols.forEach{ symbol in
                sanitizedFileName = sanitizedFileName.replacingOccurrences(of: symbol, with: "_")
            }
        }

        return sanitizedFileName
    }
}
