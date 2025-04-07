package com.inyun.heyloandroid.ui.screens

import android.Manifest
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import java.io.File
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
// Removed unused import
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
// Removed unused import
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.res.painterResource
import coil.compose.AsyncImage
import coil.request.ImageRequest
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.ViewModelProvider
import com.inyun.heyloandroid.R
import com.inyun.heyloandroid.ui.components.AnimatedPlaceholderTextField
import com.inyun.heyloandroid.ui.components.GradientText
import com.inyun.heyloandroid.ui.components.HeyloButton
import com.inyun.heyloandroid.ui.components.HeyloButtonStyle
import com.inyun.heyloandroid.ui.viewmodels.SignUpViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignUpScreen(
    onNavigateBack: () -> Unit,
    onNavigateToEmailVerification: () -> Unit,
    viewModel: SignUpViewModel = viewModel(factory = ViewModelProvider.AndroidViewModelFactory.getInstance(LocalContext.current.applicationContext as android.app.Application))
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { androidx.compose.material3.SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    // We're not using the image source dialog anymore

    // Handle UI state changes
    LaunchedEffect(uiState.isSignUpSuccessful) {
        if (uiState.isSignUpSuccessful) {
            android.util.Log.d("SignUpScreen", "Sign up successful, navigating to email verification")
            onNavigateToEmailVerification()
            viewModel.resetState()
        }
    }

    // Show error messages
    LaunchedEffect(uiState.errorMessage) {
        uiState.errorMessage?.let { error ->
            scope.launch {
                snackbarHostState.showSnackbar(error)
            }
            viewModel.clearError()
        }
    }

    // Show rate limit reset success message
    LaunchedEffect(uiState.rateLimitResetSuccess) {
        if (uiState.rateLimitResetSuccess) {
            scope.launch {
                snackbarHostState.showSnackbar("Rate limiters reset successfully")
            }
        }
    }

    // Create image URI function
    val createImageUri = remember {
        {
            val uri = com.inyun.heyloandroid.utils.ComposeFileProvider.getImageUri(context)
            viewModel.updateProfileImageUri(uri)
            uri
        }
    }

    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            // Log success with URI details
            android.util.Log.d("SignUpScreen", "Photo captured successfully: ${uiState.profileImageUri}")

            // Check if the file exists
            uiState.profileImageUri?.let { uri ->
                try {
                    val inputStream = context.contentResolver.openInputStream(uri)
                    inputStream?.close()
                    android.util.Log.d("SignUpScreen", "File exists and can be opened")
                } catch (e: Exception) {
                    android.util.Log.e("SignUpScreen", "Error checking file: ${e.message}")
                }
            }

            // Force refresh by updating the URI again
            uiState.profileImageUri?.let { uri ->
                viewModel.updateProfileImageUri(uri)
            }

            // Show a success message to the user
            scope.launch {
                snackbarHostState.showSnackbar("Profile photo updated")
            }
        } else {
            // Show error message if photo capture failed
            android.util.Log.e("SignUpScreen", "Failed to capture photo")
            scope.launch {
                snackbarHostState.showSnackbar("Failed to capture photo")
            }
        }
    }

    // We're not using gallery picker anymore

    // Permission launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            // Permission granted, launch camera
            cameraLauncher.launch(createImageUri())
        } else {
            // Show error message if permission denied
            scope.launch {
                snackbarHostState.showSnackbar("Camera permission is required to take a profile picture")
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black,
                    navigationIconContentColor = Color.White
                )
            )
        },
        containerColor = Color.Black,
        snackbarHost = {
            androidx.compose.material3.SnackbarHost(
                hostState = snackbarHostState
            ) { data ->
                androidx.compose.material3.Snackbar(
                    containerColor = Color.DarkGray,
                    contentColor = Color.White,
                ) {
                    Text(text = data.visuals.message)
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Heylo Title
                GradientText(
                    text = "Heylo",
                    fontSize = 48.sp,
                    modifier = Modifier.padding(bottom = 10.dp)
                )

                // Create Account Text
                Text(
                    text = "Create Account",
                    color = Color.White,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 30.dp)
                )

                // Profile Image
                Box(
                    modifier = Modifier
                        .size(150.dp)
                        .padding(bottom = 30.dp),
                    contentAlignment = Alignment.BottomEnd
                ) {
                    // Profile Image or Placeholder
                    Box(
                        modifier = Modifier
                            .size(150.dp)
                            .clip(CircleShape)
                            .background(Color.DarkGray)
                            .border(2.dp, Color.White, CircleShape)
                            .clickable {
                                // Request camera permission directly
                                permissionLauncher.launch(Manifest.permission.CAMERA)
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        if (uiState.profileImageUri != null) {
                            // Display the selected image with version to force refresh
                            AsyncImage(
                                model = ImageRequest.Builder(LocalContext.current)
                                    .data(uiState.profileImageUri)
                                    .setParameter("version", uiState.imageVersion, memoryCacheKey = null)
                                    .build(),
                                contentDescription = "Profile Image",
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop,
                                error = painterResource(id = R.drawable.ic_launcher_foreground)
                            )

                            // Log that we're displaying the image
                            android.util.Log.d("SignUpScreen", "Displaying image: ${uiState.profileImageUri}, version: ${uiState.imageVersion}")
                        } else {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = "Profile",
                                tint = Color.White,
                                modifier = Modifier.size(80.dp)
                            )
                        }
                    }

                    // Camera Icon
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color.Black)
                            .border(1.dp, Color.White, CircleShape)
                            .clickable {
                                cameraLauncher.launch(createImageUri())
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Take Photo",
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }

                // Display Name TextField
                AnimatedPlaceholderTextField(
                    value = uiState.displayName,
                    onValueChange = { viewModel.updateDisplayName(it) },
                    placeholder = "Display Name",
                    imeAction = ImeAction.Next,
                    modifier = Modifier.padding(bottom = 20.dp)
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
                    imeAction = ImeAction.Next,
                    modifier = Modifier.padding(bottom = 20.dp)
                )

                // Confirm Password TextField
                AnimatedPlaceholderTextField(
                    value = uiState.confirmPassword,
                    onValueChange = { viewModel.updateConfirmPassword(it) },
                    placeholder = "Confirm Password",
                    isPassword = true,
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done,
                    onImeAction = {
                        if (isFormValid(uiState)) {
                            viewModel.signUp()
                        }
                    },
                    modifier = Modifier.padding(bottom = 40.dp)
                )

                // Sign Up Button
                HeyloButton(
                    text = "Sign Up",
                    onClick = {
                        android.util.Log.d("SignUpScreen", "Sign up button clicked")
                        viewModel.signUp()
                    },
                    enabled = !uiState.isLoading && !uiState.isResettingRateLimit && isFormValid(uiState),
                    modifier = Modifier.padding(bottom = 20.dp)
                )

                // Rate Limit Reset Button (only shown when rate limit error occurs)
                if (uiState.showResetRateLimitOption) {
                    HeyloButton(
                        text = if (uiState.isResettingRateLimit) "Resetting..." else "Reset Rate Limiters",
                        onClick = { viewModel.resetRateLimiters() },
                        style = HeyloButtonStyle.SECONDARY,
                        enabled = !uiState.isResettingRateLimit
                    )
                }
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
        }
    }

    // We're not using the image source dialog anymore
}

private fun isFormValid(uiState: com.inyun.heyloandroid.ui.viewmodels.SignUpUiState): Boolean {
    return uiState.displayName.isNotEmpty() &&
            uiState.email.isNotEmpty() &&
            uiState.password.isNotEmpty() &&
            uiState.confirmPassword.isNotEmpty() &&
            uiState.password == uiState.confirmPassword
}
