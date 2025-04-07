package com.inyun.heyloandroid.utils

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import com.inyun.heyloandroid.R
import java.io.File

/**
 * FileProvider for Jetpack Compose camera integration
 */
class ComposeFileProvider : FileProvider(R.xml.file_paths) {
    companion object {
        /**
         * Creates a temporary file and returns its URI
         */
        fun getImageUri(context: Context): Uri {
            val directory = File(context.cacheDir, "images")
            directory.mkdirs()
            val file = File.createTempFile(
                "camera_photo_",
                ".jpg",
                directory
            )
            val authority = "com.inyun.heyloandroid.fileprovider"
            return getUriForFile(
                context,
                authority,
                file
            )
        }
    }
}
