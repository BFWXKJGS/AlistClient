package com.github.alist.utils;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;

import androidx.core.content.FileProvider;

import java.io.File;

public class FileProviderUtils {
    public static Uri getUriFromFile(Context context, File file) {
        Uri uri;
        if (Build.VERSION.SDK_INT >= 24) {
            uri = getUriForFile24(context, file);
        } else {
            uri = Uri.fromFile(file);
        }
        return uri;
    }

    public static Uri getUriForFile24(Context context, File file) {
        return FileProvider.getUriForFile(context,
                String.format("%s.alist_file_provider", context.getPackageName()), file);
    }

    public static void setIntentDataAndType(Context context,
                                            Intent intent,
                                            String type,
                                            File file,
                                            boolean writeAble) {
        if (Build.VERSION.SDK_INT >= 24) {
            intent.setDataAndType(getUriForFile24(context, file), type);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            if (writeAble) {
                intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            }
        } else {
            intent.setDataAndType(Uri.fromFile(file), type);
        }
    }
}
