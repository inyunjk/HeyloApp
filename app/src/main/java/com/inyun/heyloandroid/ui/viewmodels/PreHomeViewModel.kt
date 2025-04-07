package com.inyun.heyloandroid.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.inyun.heyloandroid.services.AuthService
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PreHomeViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(PreHomeUiState())
    val uiState: StateFlow<PreHomeUiState> = _uiState.asStateFlow()

    private val authService = AuthService.getInstance(application)
    private val maxCheckCount = 10

    init {
        checkEmailVerification()
    }

    private fun checkEmailVerification() {
        viewModelScope.launch {
            var checkCount = 0

            // Always show the loading animation for at least 3 seconds
            _uiState.value = _uiState.value.copy(
                statusText = "Loading Heylo..."
            )
            delay(3000) // Show loading animation for 3 seconds

            // Now check email verification silently (without updating UI)
            // Check email verification using the secure backend function
            val result = authService.checkEmailVerification()

            result.fold(
                onSuccess = { isVerified ->
                    if (isVerified) {
                        // Don't show any message, just set the flag and complete
                        _uiState.value = _uiState.value.copy(
                            isEmailVerified = true,
                            animationComplete = true
                        )
                        return@fold
                    }

                    // If not verified, start the verification check loop
                    checkVerificationLoop()
                },
                onFailure = { error ->
                    // Log the error and start the verification check loop
                    android.util.Log.e("PreHomeViewModel", "Error checking email verification: ${error.message}")
                    checkVerificationLoop()
                }
            )
        }
    }

    private suspend fun checkVerificationLoop() {
        var checkCount = 0

        while (checkCount < maxCheckCount) {
            checkCount++
            _uiState.value = _uiState.value.copy(
                statusText = "Checking email verification... ($checkCount/$maxCheckCount)"
            )

            // Check email verification using the secure backend function
            val result = authService.checkEmailVerification()

            result.fold(
                onSuccess = { isVerified ->
                    if (isVerified) {
                        // Don't show any message, just set the flag and complete
                        _uiState.value = _uiState.value.copy(
                            isEmailVerified = true,
                            animationComplete = true
                        )
                        return@fold
                    }

                    if (checkCount >= maxCheckCount) {
                        _uiState.value = _uiState.value.copy(
                            statusText = "Email verification timeout. Please try again later.",
                            isTimeout = true,
                            animationComplete = true
                        )
                        return@fold
                    }
                },
                onFailure = { error ->
                    // Log the error but continue checking
                    android.util.Log.e("PreHomeViewModel", "Error checking email verification: ${error.message}")

                    if (checkCount >= maxCheckCount) {
                        _uiState.value = _uiState.value.copy(
                            statusText = "Email verification timeout. Please try again later.",
                            isTimeout = true,
                            animationComplete = true
                        )
                        return@fold
                    }
                }
            )

            delay(3000) // Wait 3 seconds between checks
        }
    }
}

data class PreHomeUiState(
    val statusText: String = "Loading...",
    val isEmailVerified: Boolean = false,
    val isTimeout: Boolean = false,
    val animationComplete: Boolean = false
)
