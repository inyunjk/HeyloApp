package com.inyun.heyloandroid.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.ViewModelProvider
import androidx.compose.ui.platform.LocalContext
import com.inyun.heyloandroid.ui.components.AnimatedPlaceholderTextField
import com.inyun.heyloandroid.ui.components.GradientSpanText
import com.inyun.heyloandroid.ui.components.GradientText
import com.inyun.heyloandroid.ui.components.HeyloButton
import com.inyun.heyloandroid.ui.components.HeyloButtonStyle
import com.inyun.heyloandroid.ui.navigation.Screen
import com.inyun.heyloandroid.ui.viewmodels.SignInViewModel
import androidx.navigation.NavController
import kotlinx.coroutines.launch

@Composable
fun SignInScreen(
    onNavigateToSignUp: () -> Unit,
    onNavigateToHome: () -> Unit,
    onNavigateToEmailVerification: () -> Unit,
    navController: NavController,
    viewModel: SignInViewModel = viewModel(factory = ViewModelProvider.AndroidViewModelFactory.getInstance(LocalContext.current.applicationContext as android.app.Application))
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    // Handle UI state changes
    LaunchedEffect(uiState.isSignInSuccessful, uiState.isEmailVerified) {
        if (uiState.isSignInSuccessful) {
            // Always navigate to PreHomeScreen first to show loading animation
            // The PreHomeScreen will handle navigation to Home or EmailVerification
            navController.navigate(Screen.PreHome.route) {
                popUpTo(Screen.SignIn.route) { inclusive = true }
            }
            viewModel.resetState()
        }
    }

    // Show error messages
    LaunchedEffect(uiState.errorMessage) {
        uiState.errorMessage?.let { error ->
            scope.launch {
                snackbarHostState.showSnackbar(message = error)
            }
            viewModel.clearError()
        }
    }

    // Show rate limit reset success message
    LaunchedEffect(uiState.rateLimitResetSuccess) {
        if (uiState.rateLimitResetSuccess) {
            scope.launch {
                snackbarHostState.showSnackbar(message = "Rate limiters reset successfully")
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(80.dp))

            // Heylo Title
            GradientText(
                text = "Heylo",
                fontSize = 72.sp,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Subtitle with gradient span
            GradientSpanText(
                text = "Discover real connections near you",
                gradientText = "real connections",
                fontSize = 16.sp,
                color = Color.LightGray,
                modifier = Modifier.padding(bottom = 60.dp)
            )

            // Email TextField
            AnimatedPlaceholderTextField(
                value = uiState.email,
                onValueChange = { viewModel.updateEmail(it) },
                placeholder = "Email",
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Password TextField
            AnimatedPlaceholderTextField(
                value = uiState.password,
                onValueChange = { viewModel.updatePassword(it) },
                placeholder = "Password",
                isPassword = true,
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done,
                onImeAction = {
                    if (uiState.email.isNotEmpty() && uiState.password.isNotEmpty()) {
                        viewModel.signIn()
                    }
                },
                modifier = Modifier.padding(bottom = 40.dp)
            )

            // Sign In Button
            HeyloButton(
                text = "Sign In",
                onClick = { viewModel.signIn() },
                enabled = !uiState.isLoading && !uiState.isResettingRateLimit &&
                         uiState.email.isNotEmpty() && uiState.password.isNotEmpty(),
                modifier = Modifier.padding(bottom = 20.dp)
            )

            // Rate Limit Reset Button (only shown when rate limit error occurs)
            if (uiState.showResetRateLimitOption) {
                HeyloButton(
                    text = if (uiState.isResettingRateLimit) "Resetting..." else "Reset Rate Limiters",
                    onClick = { viewModel.resetRateLimiters() },
                    style = HeyloButtonStyle.SECONDARY,
                    enabled = !uiState.isResettingRateLimit,
                    modifier = Modifier.padding(bottom = 20.dp)
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Sign Up Button
            HeyloButton(
                text = "Don't have an account? Sign Up",
                onClick = onNavigateToSignUp,
                style = HeyloButtonStyle.TEXT,
                enabled = !uiState.isLoading
            )
        }

        // Loading Indicator
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(48.dp),
                    color = Color.White
                )
            }
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
