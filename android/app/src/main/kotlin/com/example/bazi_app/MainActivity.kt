package com.example.bazi_app

import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Flutter Surface 未就绪前显示米色，避免纯黑窗口
        window.decorView.setBackgroundColor(Color.parseColor("#FFF7F3EC"))
    }
}
