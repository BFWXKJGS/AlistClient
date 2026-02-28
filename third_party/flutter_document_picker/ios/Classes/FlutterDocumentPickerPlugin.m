#import "FlutterDocumentPickerPlugin.h"
#import <flutter_document_picker/flutter_document_picker-Swift.h>

@implementation FlutterDocumentPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterDocumentPickerPlugin registerWithRegistrar:registrar];
}
@end
