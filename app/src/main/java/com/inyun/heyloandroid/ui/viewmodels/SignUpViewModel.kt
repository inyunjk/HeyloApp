package com.inyun.heyloandroid.ui.viewmodels

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.inyun.heyloandroid.services.AuthService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class SignUpViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(SignUpUiState())
    val uiState: StateFlow<SignUpUiState> = _uiState.asStateFlow()

    private val authService = AuthService.getInstance(application)

    fun updateDisplayName(displayName: String) {
        _uiState.value = _uiState.value.copy(displayName = displayName)
    }

    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email)
    }

    fun updatePassword(password: String) {
        _uiState.value = _uiState.value.copy(password = password)
    }

    fun updateConfirmPassword(confirmPassword: String) {
        _uiState.value = _uiState.value.copy(confirmPassword = confirmPassword)
    }

    fun updateProfileImageUri(uri: Uri?) {
        // Update the URI and increment the version counter to force refresh
        _uiState.value = _uiState.value.copy(
            profileImageUri = uri,
            imageVersion = System.currentTimeMillis() // Use current time as version
        )
        android.util.Log.d("SignUpViewModel", "Updated profile image URI: $uri, version: ${_uiState.value.imageVersion}")
    }

    // Flag to prevent multiple rapid sign-up attempts
    private var isSigningUp = false

    fun signUp() {
        android.util.Log.d("SignUpViewModel", "signUp() called")
        // Prevent multiple rapid taps
        if (isSigningUp) {
            android.util.Log.d("SignUpViewModel", "Already signing up, ignoring tap")
            return
        }
        isSigningUp = true

        android.util.Log.d("SignUpViewModel", "Starting sign-up process with profile image: ${_uiState.value.profileImageUri}")

        val currentState = _uiState.value
        val displayName = currentState.displayName
        val email = currentState.email
        val password = currentState.password
        val confirmPassword = currentState.confirmPassword

        // Validate inputs
        if (displayName.isEmpty()) {
            _uiState.value = currentState.copy(errorMessage = "Please enter a display name")
            isSigningUp = false
            return
        }

        if (email.isEmpty()) {
            _uiState.value = currentState.copy(errorMessage = "Please enter an email")
            isSigningUp = false
            return
        }

        if (password.isEmpty()) {
            _uiState.value = currentState.copy(errorMessage = "Please enter a password")
            isSigningUp = false
            return
        }

        if (confirmPassword.isEmpty()) {
            _uiState.value = currentState.copy(errorMessage = "Please confirm your password")
            isSigningUp = false
            return
        }

        if (password != confirmPassword) {
            _uiState.value = currentState.copy(errorMessage = "Passwords do not match")
            isSigningUp = false
            return
        }

        _uiState.value = currentState.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                val result = authService.signUp(
                    email = email,
                    password = password,
                    displayName = displayName,
                    profileImageUri = currentState.profileImageUri
                )

                result.fold(
                    onSuccess = { user ->
                        android.util.Log.d("SignUpViewModel", "Sign up successful: $user")
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            isSignUpSuccessful = true
                        )
                        android.util.Log.d("SignUpViewModel", "Updated UI state: ${_uiState.value}")
                        android.util.Log.d("SignUpViewModel", "isSignUpSuccessful is now: ${_uiState.value.isSignUpSuccessful}")
                    },
                    onFailure = { error ->
                        val errorMessage = error.message ?: "Sign up failed"
                        val isRateLimitError = errorMessage.contains("too many") ||
                                              errorMessage.contains("rate limit")

                        _uiState.value = currentState.copy(
                            isLoading = false,
                            errorMessage = errorMessage,
                            showResetRateLimitOption = isRateLimitError
                        )
                    }
                )
            } catch (e: Exception) {
                _uiState.value = currentState.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Sign up failed"
                )
            } finally {
                // Reset the signing up flag
                isSigningUp = false
            }
        }
    }

    fun resetRateLimiters() {
        _uiState.value = _uiState.value.copy(isResettingRateLimit = true, errorMessage = null)

        viewModelScope.launch {
            try {
                val result = authService.resetRateLimiters()

                result.fold(
                    onSuccess = {
                        _uiState.value = _uiState.value.copy(
                            isResettingRateLimit = false,
                            rateLimitResetSuccess = true,
                            showResetRateLimitOption = false
                        )
                    },
                    onFailure = { error ->
                        _uiState.value = _uiState.value.copy(
                            isResettingRateLimit = false,
                            errorMessage = "Failed to reset rate limiters: ${error.message}"
                        )
                    }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isResettingRateLimit = false,
                    errorMessage = "Failed to reset rate limiters: ${e.message}"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun resetState() {
        _uiState.value = SignUpUiState()
    }
}

data class SignUpUiState(
    val displayName: String = "",
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val profileImageUri: Uri? = null,
    val imageVersion: Long = 0, // Add a version counter to force refresh
    val isLoading: Boolean = false,
    val isSignUpSuccessful: Boolean = false,
    val errorMessage: String? = null,
    val showResetRateLimitOption: Boolean = false,
    val isResettingRateLimit: Boolean = false,
    val rateLimitResetSuccess: Boolean = false
)
