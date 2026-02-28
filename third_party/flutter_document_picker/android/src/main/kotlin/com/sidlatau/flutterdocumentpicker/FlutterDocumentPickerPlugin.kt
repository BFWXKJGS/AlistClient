package com.sidlatau.flutterdocumentpicker

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterDocumentPickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var delegate: FlutterDocumentPickerDelegate? = null
    private var activityBinding: ActivityPluginBinding? = null


    companion object {
        const val TAG = "flutter_document_picker"
        private const val ARG_ALLOWED_FILE_EXTENSIONS = "allowedFileExtensions"
        private const val ARG_ALLOWED_MIME_TYPES = "allowedMimeTypes"
        private const val ARG_INVALID_FILENAME_SYMBOLS = "invalidFileNameSymbols"
        private const val ARG_IS_MULTIPLE_SELECTION = "isMultipleSelection"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "flutter_document_picker")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding

        val delegate = FlutterDocumentPickerDelegate(
            activity = binding.activity
        )
        binding.addActivityResultListener(delegate)

        this.delegate = delegate

    }

    override fun onDetachedFromActivity() {
        delegate?.let { activityBinding?.removeActivityResultListener(it) }
        delegate = null
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "pickDocument") {
            delegate?.pickDocument(
                result,
                allowedFileExtensions = parseArray(call, ARG_ALLOWED_FILE_EXTENSIONS),
                allowedMimeTypes = parseArray(call, ARG_ALLOWED_MIME_TYPES),
                invalidFileNameSymbols = parseArray(call, ARG_INVALID_FILENAME_SYMBOLS),
                isMultipleSelection = call.argument(ARG_IS_MULTIPLE_SELECTION)
            )
        } else {
            result.notImplemented()
        }
    }

    private fun parseArray(call: MethodCall, arg: String): Array<String>? {
        if (call.hasArgument(arg)) {
            return call.argument<ArrayList<String>>(arg)?.toTypedArray()
        }
        return null
    }
}
