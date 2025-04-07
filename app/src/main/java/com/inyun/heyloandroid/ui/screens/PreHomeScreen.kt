package com.inyun.heyloandroid.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.ViewModelProvider
import androidx.compose.ui.platform.LocalContext
import com.inyun.heyloandroid.ui.components.LoadingAnimation
import com.inyun.heyloandroid.ui.viewmodels.PreHomeViewModel

@Composable
fun PreHomeScreen(
    onNavigateToHome: () -> Unit,
    onNavigateToEmailVerification: () -> Unit,
    viewModel: PreHomeViewModel = viewModel(factory = ViewModelProvider.AndroidViewModelFactory.getInstance(LocalContext.current.applicationContext as android.app.Application))
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle navigation based on verification status
    // Only navigate when the status changes and after the animation completes
    LaunchedEffect(uiState.isEmailVerified, uiState.isTimeout, uiState.animationComplete) {
        if (uiState.animationComplete) {
            if (uiState.isEmailVerified) {
                onNavigateToHome()
            } else if (uiState.isTimeout) {
                onNavigateToEmailVerification()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Heylo Title
            Text(
                text = "Heylo",
                color = Color.White,
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 40.dp)
            )

            // Loading Animation
            LoadingAnimation(
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Status Text
            Text(
                text = uiState.statusText,
                color = Color.White,
                fontSize = 18.sp
            )
        }
    }
}
