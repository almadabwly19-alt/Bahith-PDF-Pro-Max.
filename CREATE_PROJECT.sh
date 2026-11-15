#!/usr/bin/env bash
set -euo pipefail

# Generates the Android project folders and source files from this single script.
ROOT="$(pwd)"

mkdir -p app/src/main/java/com/bahith/pdf
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable

cat > settings.gradle.kts <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BahithPDFProMax"
include(":app")
EOF

cat > build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
org.gradle.parallel=true
EOF

cat > app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.bahith.pdf"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.bahith.pdf"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:label="باحث PDF Pro Max"
        android:theme="@style/AppTheme"
        android:supportsRtl="true">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > app/src/main/res/values/styles.xml <<'EOF'
<resources>
    <style name="AppTheme" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:colorAccent">#D6A84F</item>
        <item name="android:statusBarColor">#071A33</item>
        <item name="android:navigationBarColor">#071A33</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
</resources>
EOF

cat > app/src/main/java/com/bahith/pdf/MainActivity.kt <<'EOF'
package com.bahith.pdf

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {
    private val navy = Color.rgb(7, 26, 51)
    private val gold = Color.rgb(214, 168, 79)
    private var descriptor: ParcelFileDescriptor? = null
    private var renderer: PdfRenderer? = null
    private var pageIndex = 0
    private lateinit var pageImage: ImageView
    private lateinit var pageLabel: TextView
    private lateinit var openButton: Button
    private lateinit var previousButton: Button
    private lateinit var nextButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildScreen()
    }

    private fun buildScreen() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(navy)
            setPadding(18, 22, 18, 18)
            layoutDirection = LinearLayout.LAYOUT_DIRECTION_RTL
        }

        val title = TextView(this).apply {
            text = "باحث PDF Pro Max"
            textSize = 25f
            setTextColor(gold)
            gravity = Gravity.CENTER
            setPadding(8, 14, 8, 18)
        }
        root.addView(title, LinearLayout.LayoutParams(-1, -2))

        val subtitle = TextView(this).apply {
            text = "قارئ ملفات PDF"
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(8, 0, 8, 14)
        }
        root.addView(subtitle, LinearLayout.LayoutParams(-1, -2))

        openButton = Button(this).apply {
            text = "اختيار ملف PDF"
            setOnClickListener { choosePdf() }
        }
        root.addView(openButton, LinearLayout.LayoutParams(-1, -2))

        pageLabel = TextView(this).apply {
            text = "لم يتم فتح ملف بعد"
            textSize = 14f
            setTextColor(gold)
            gravity = Gravity.CENTER
            setPadding(8, 12, 8, 12)
        }
        root.addView(pageLabel, LinearLayout.LayoutParams(-1, -2))

        pageImage = ImageView(this).apply {
            adjustViewBounds = true
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(Color.WHITE)
            setPadding(4, 4, 4, 4)
        }
        root.addView(pageImage, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ))

        val controls = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutDirection = LinearLayout.LAYOUT_DIRECTION_LTR
        }
        previousButton = Button(this).apply {
            text = "السابق"
            isEnabled = false
            setOnClickListener { showPage(pageIndex - 1) }
        }
        nextButton = Button(this).apply {
            text = "التالي"
            isEnabled = false
            setOnClickListener { showPage(pageIndex + 1) }
        }
        controls.addView(previousButton, LinearLayout.LayoutParams(0, -2, 1f))
        controls.addView(nextButton, LinearLayout.LayoutParams(0, -2, 1f))
        root.addView(controls, LinearLayout.LayoutParams(-1, -2))
        setContentView(root)
    }

    private fun choosePdf() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/pdf"
        }
        startActivityForResult(intent, REQUEST_PDF)
    }

    @Deprecated("Deprecated by platform; retained for broad Android compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_PDF && resultCode == RESULT_OK) {
            val uri = data?.data ?: return
            try {
                openDocument(uri)
            } catch (e: Exception) {
                Toast.makeText(this, "تعذر فتح الملف: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun openDocument(uri: Uri) {
        closeDocument()
        descriptor = contentResolver.openFileDescriptor(uri, "r")
            ?: throw IllegalStateException("لم يتمكن النظام من فتح الملف")
        renderer = PdfRenderer(descriptor!!)
        pageIndex = 0
        showPage(0)
    }

    private fun showPage(index: Int) {
        val pdf = renderer ?: return
        if (index !in 0 until pdf.pageCount) return
        val page = pdf.openPage(index)
        val width = (resources.displayMetrics.widthPixels * 0.88f).toInt()
        val height = (width.toFloat() * page.height / page.width).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.WHITE)
        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        page.close()
        pageImage.setImageBitmap(bitmap)
        pageIndex = index
        pageLabel.text = "الصفحة ${index + 1} من ${pdf.pageCount}"
        previousButton.isEnabled = index > 0
        nextButton.isEnabled = index < pdf.pageCount - 1
    }

    private fun closeDocument() {
        renderer?.close()
        renderer = null
        descriptor?.close()
        descriptor = null
    }

    override fun onDestroy() {
        closeDocument()
        super.onDestroy()
    }

    companion object {
        private const val REQUEST_PDF = 4102
    }
}
EOF

echo "Project files generated."
echo "Expected files: settings.gradle.kts, build.gradle.kts, gradle.properties, app/..."
