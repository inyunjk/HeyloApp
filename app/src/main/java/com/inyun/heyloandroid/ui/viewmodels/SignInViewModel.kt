package com.inyun.heyloandroid.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.inyun.heyloandroid.services.AuthService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class SignInViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(SignInUiState())
    val uiState: StateFlow<SignInUiState> = _uiState.asStateFlow()

    private val authService = AuthService.getInstance(application)

    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email)
    }

    fun updatePassword(password: String) {
        _uiState.value = _uiState.value.copy(password = password)
    }

    // Flag to prevent multiple rapid sign-in attempts
    private var isSigningIn = false

    fun signIn() {
        // Prevent multiple rapid taps
        if (isSigningIn) return
        isSigningIn = true

        val email = _uiState.value.email
        val password = _uiState.value.password

        if (email.isEmpty() || password.isEmpty()) {
            _uiState.value = _uiState.value.copy(
                errorMessage = "Please enter both email and password"
            )
            isSigningIn = false
            return
        }

        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                val result = authService.signIn(email, password)

                result.fold(
                    onSuccess = { user ->
                        if (user.isEmailVerified) {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isSignInSuccessful = true,
                                isEmailVerified = true
                            )
                        } else {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isSignInSuccessful = true,
                                isEmailVerified = false
                            )
                        }
                    },
                    onFailure = { error ->
                        val errorMessage = error.message ?: "Authentication failed"
                        val isRateLimitError = errorMessage.contains("too many") ||
                                              errorMessage.contains("rate limit")

                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            errorMessage = errorMessage,
                            showResetRateLimitOption = isRateLimitError
                        )
                    }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Authentication failed"
                )
            }

            // Reset the signing in flag
            isSigningIn = false
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
        _uiState.value = SignInUiState()
    }
}

data class SignInUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val isSignInSuccessful: Boolean = false,
    val isEmailVerified: Boolean = false,
    val errorMessage: String? = null,
    val showResetRateLimitOption: Boolean = false,
    val isResettingRateLimit: Boolean = false,
    val rateLimitResetSuccess: Boolean = false
)
