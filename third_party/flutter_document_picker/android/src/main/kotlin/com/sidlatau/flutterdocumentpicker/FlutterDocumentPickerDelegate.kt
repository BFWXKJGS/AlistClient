package com.sidlatau.flutterdocumentpicker

import android.app.Activity
import android.app.LoaderManager
import android.content.AsyncTaskLoader
import android.content.Context
import android.content.Intent
import android.content.Loader
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream

private const val REQUEST_CODE_PICK_FILE = 603
private const val EXTRA_URI = "EXTRA_URI"
private const val EXTRA_FILENAME = "EXTRA_FILENAME"
private const val LOADER_FILE_COPY = 603

class FlutterDocumentPickerDelegate(
    private val activity: Activity
) : PluginRegistry.ActivityResultListener, LoaderManager.LoaderCallbacks<List<FileCopyTaskLoaderResult>> {
    private var channelResult: MethodChannel.Result? = null
    private var allowedFileExtensions: Array<String>? = null
    private var invalidFileNameSymbols: Array<String>? = null
    private var isMultipleSelection: Boolean? = null

    fun pickDocument(result: MethodChannel.Result,
                     allowedFileExtensions: Array<String>?,
                     allowedMimeTypes: Array<String>?,
                     invalidFileNameSymbols: Array<String>?,
                     isMultipleSelection: Boolean?
    ) {
        channelResult = result
        this.allowedFileExtensions = allowedFileExtensions
        this.invalidFileNameSymbols = invalidFileNameSymbols
        this.isMultipleSelection = isMultipleSelection

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)

        if (allowedMimeTypes != null) {
            if (allowedMimeTypes.size == 1) {
                intent.type = allowedMimeTypes.first()
            } else {
                intent.type = "*/*"
                intent.putExtra(Intent.EXTRA_MIME_TYPES, allowedMimeTypes)
            }
        } else {
            intent.type = "*/*"
        }
        if(isMultipleSelection == true){
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        }

        activity.startActivityForResult(intent, REQUEST_CODE_PICK_FILE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_PICK_FILE -> {
                val params = getFileCopyParams(resultCode, data)
                val channelResult = channelResult
                val allowedFileExtensions = allowedFileExtensions
                val intersectedExtensions = allowedFileExtensions?.intersect(params.map { param -> param.extension }.toSet()) ?: setOf()
                if (params.isNotEmpty()) {
                    if (allowedFileExtensions != null && intersectedExtensions.isEmpty()) {
                        channelResult?.error("extension_mismatch", "Picked file extension mismatch!", params.first().extension)
                    } else {
                        startLoader(params)
                    }
                } else {
                    channelResult?.success(null)
                }
                return true
            }
            else -> {
                false
            }
        }
    }

    private fun startLoader(listParams: List<FileCopyParams>) {
        for(params in listParams){
            val bundle = Bundle()
            bundle.putParcelableArray(EXTRA_URI, listParams.map { p -> p.uri }.toTypedArray())
            bundle.putStringArray(EXTRA_FILENAME, listParams.map { p -> p.fileName }.toTypedArray())

            val loaderManager = activity.loaderManager
            val loader = loaderManager.getLoader<String>(LOADER_FILE_COPY)
            if (loader == null) {
                loaderManager.initLoader(LOADER_FILE_COPY, bundle, this)
            } else {
                loaderManager.restartLoader(LOADER_FILE_COPY, bundle, this)
            }
        }
    }

    override fun onCreateLoader(id: Int, args: Bundle): Loader<List<FileCopyTaskLoaderResult>> {

        val listUri = (args.getParcelableArray(EXTRA_URI)!! as Array<Uri>).toList()
        val listFileName = (args.getStringArray(EXTRA_FILENAME)!! as Array<String>).toList()
        return FileCopyTaskLoader(activity, listUri, listFileName)
    }

    override fun onLoadFinished(loader: Loader<List<FileCopyTaskLoaderResult>>?, data: List<FileCopyTaskLoaderResult>) {
        if(data.any { it.isSuccess() }) {
            channelResult?.success(data.map {  it.result }.toList())
        } else {
            channelResult?.error("LOAD_FAILED", data.first {  it.error != null }.error.toString(), null)
        }
        activity.loaderManager.destroyLoader(LOADER_FILE_COPY)
    }

    override fun onLoaderReset(loader: Loader<List<FileCopyTaskLoaderResult>>?) {
    }

    private fun getFileCopyParams(resultCode: Int, data: Intent?): List<FileCopyParams> {
        if (resultCode == Activity.RESULT_OK) {
            try {
                val resultListUri = mutableListOf<FileCopyParams>()
                val uri = data?.data
                if (uri != null) {
                    val parseParams = parseFileCopyParams(uri)
                    if(parseParams != null){
                        resultListUri.add(parseParams)
                    }
                }
                else{
                    for (index in 0 until (data?.clipData?.itemCount ?: 0)){
                        val uri = data?.clipData?.getItemAt(index)?.uri
                        if (uri != null) {
                            val parseParams = parseFileCopyParams(uri)
                            if(parseParams != null){
                                resultListUri.add(parseParams)
                            }
                        }
                    }
                }
                return resultListUri
            } catch (e: Exception) {
                Log.e(FlutterDocumentPickerPlugin.TAG, "handlePickFileResult", e)
            }
        }
        return listOf()
    }

    private fun parseFileCopyParams(uri: Uri): FileCopyParams? {
        val fileName = getFileName(uri)
        if (fileName != null) {
            val sanitizedFileName = sanitizeFileName(fileName)
            return FileCopyParams(
                uri = uri,
                fileName = sanitizedFileName,
                extension = getFileExtension(sanitizedFileName)
            )
        }
        return null
    }



    private fun sanitizeFileName(fileName: String): String {
        var sanitizedFileName = fileName
        val invalidSymbols = invalidFileNameSymbols
        if (!invalidSymbols.isNullOrEmpty()) {
            invalidSymbols.forEach {
                sanitizedFileName = sanitizedFileName.replace(it, "_")
            }

        }
        return sanitizedFileName
    }

    private fun getFileExtension(fileName: String): String? {
        val dotIndex = fileName.lastIndexOf(".") + 1
        if (dotIndex > 0 && fileName.length > dotIndex) {
            return fileName.substring(dotIndex)
        }
        return null
    }

    private fun getFileName(uri: Uri): String? {
        var fileName: String? = null
        activity.contentResolver.query(uri, null, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if(index >=0) {
                    fileName = cursor.getString(index)
                }
            }
        }
        return fileName
    }
}

data class FileCopyParams(val uri: Uri, val fileName: String, val extension: String?)

class FileCopyTaskLoader(context: Context, private val listUri: List<Uri>, private val listFileName: List<String>) : AsyncTaskLoader<List<FileCopyTaskLoaderResult>>(context) {
    override fun loadInBackground(): List<FileCopyTaskLoaderResult> {
      return listUri.mapIndexed { index, uri ->  try {
           FileCopyTaskLoaderResult(copyToTemp(uri = uri, fileName = listFileName[index]))
      } catch (e: Exception) {
          Log.e(FlutterDocumentPickerPlugin.TAG, "handlePickFileResult", e)
           FileCopyTaskLoaderResult(e)
      }}.toList()
    }

    override fun onStartLoading() {
        super.onStartLoading()
        forceLoad()
    }

    private fun copyToTemp(uri: Uri, fileName: String): String {
        val path = context.cacheDir.path + File.separator + fileName

        val file = File(path)

        if (file.exists()) {
            file.delete()
        }

        BufferedInputStream(context.contentResolver.openInputStream(uri)).use { inputStream ->
            BufferedOutputStream(FileOutputStream(file)).use { outputStream ->
                val buf = ByteArray(1024)
                var len = inputStream.read(buf)
                while (len != -1) {
                    outputStream.write(buf, 0, len)
                    len = inputStream.read(buf)
                }
            }
        }

        return file.absolutePath
    }
}

class FileCopyTaskLoaderResult {
    val result: String?
    val error: Exception?

    constructor(result: String) {
        this.result = result
        this.error = null;
    }

    constructor(error: Exception) {
        this.result = null;
        this.error = error;
    }

    fun isSuccess(): Boolean {
        return error == null
    }
}