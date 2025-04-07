package com.inyun.heyloandroid.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.ViewModelProvider
import androidx.compose.ui.platform.LocalContext
import com.inyun.heyloandroid.ui.components.HeyloButton
import com.inyun.heyloandroid.ui.components.HeyloButtonStyle
import com.inyun.heyloandroid.ui.viewmodels.EmailVerificationViewModel
import kotlinx.coroutines.launch

@Composable
fun PendingEmailVerificationScreen(
    onNavigateToSignIn: () -> Unit,
    viewModel: EmailVerificationViewModel = viewModel(factory = ViewModelProvider.AndroidViewModelFactory.getInstance(LocalContext.current.applicationContext as android.app.Application))
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    // Show error messages
    LaunchedEffect(uiState.errorMessage) {
        uiState.errorMessage?.let { error ->
            scope.launch {
                snackbarHostState.showSnackbar(message = error)
            }
            viewModel.clearError()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Heylo Title
            Text(
                text = "Heylo",
                color = Color.White,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 20.dp, bottom = 30.dp)
            )

            // Email Icon
            Icon(
                imageVector = Icons.Default.Email,
                contentDescription = "Email",
                tint = Color.White,
                modifier = Modifier
                    .size(100.dp)
                    .padding(bottom = 30.dp)
            )

            // Title
            Text(
                text = "Verify Your Email",
                color = Color.White,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Message
            Text(
                text = "We've sent a verification email to your address. Please check your inbox and verify your email to continue.",
                color = Color.LightGray,
                fontSize = 16.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Email Address
            Text(
                text = uiState.email,
                color = Color.White,
                fontSize = 18.sp,
                modifier = Modifier.padding(bottom = 40.dp)
            )

            // Resend Button
            Box(
                contentAlignment = Alignment.Center
            ) {
                HeyloButton(
                    text = if (uiState.isResendSuccessful) "Email Sent!" else "Resend Verification Email",
                    onClick = { viewModel.resendVerificationEmail() },
                    style = HeyloButtonStyle.SECONDARY,
                    enabled = !uiState.isResending && !uiState.isResendSuccessful,
                    modifier = Modifier.padding(bottom = 20.dp)
                )

                if (uiState.isResending) {
                    CircularProgressIndicator(
                        modifier = Modifier
                            .size(24.dp)
                            .padding(start = 200.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                }
            }

            // Return to Sign In Button
            HeyloButton(
                text = "Return to Sign In",
                onClick = {
                    viewModel.signOut()
                    onNavigateToSignIn()
                },
                enabled = !uiState.isResending
            )
        }

        // Snackbar for error messages
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        ) { data ->
            Snackbar(
                containerColor = Color.DarkGray,
                contentColor = Color.White,
            ) {
                Text(text = data.visuals.message)
            }
        }
    }
}
