package com.inyun.heyloandroid

import android.app.Application
import com.google.firebase.FirebaseApp

class HeyloApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
    }
}
