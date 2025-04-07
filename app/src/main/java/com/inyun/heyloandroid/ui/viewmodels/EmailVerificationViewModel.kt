package com.inyun.heyloandroid.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseUser
import com.inyun.heyloandroid.services.AuthService
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class EmailVerificationViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(EmailVerificationUiState())
    val uiState: StateFlow<EmailVerificationUiState> = _uiState.asStateFlow()

    private val authService = AuthService.getInstance(application)

    init {
        val currentUser = authService.getCurrentUser()
        if (currentUser != null) {
            _uiState.value = _uiState.value.copy(
                email = currentUser.email ?: "",
                user = currentUser
            )
        }
    }

    fun resendVerificationEmail() {
        _uiState.value = _uiState.value.copy(isResending = true, errorMessage = null)

        viewModelScope.launch {
            try {
                val result = authService.sendEmailVerification()

                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isResending = false,
                            isResendSuccessful = true,
                            successMessage = message
                        )

                        // Reset success state after a delay
                        delay(3000)
                        _uiState.value = _uiState.value.copy(
                            isResendSuccessful = false,
                            successMessage = null
                        )
                    },
                    onFailure = { error ->
                        _uiState.value = _uiState.value.copy(
                            isResending = false,
                            errorMessage = error.message ?: "Failed to send verification email"
                        )
                    }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isResending = false,
                    errorMessage = e.message ?: "Failed to send verification email"
                )
            }
        }
    }

    suspend fun checkEmailVerification(): Boolean {
        val result = authService.checkEmailVerification()

        return result.fold(
            onSuccess = { isVerified -> isVerified },
            onFailure = { false }
        )
    }

    fun signOut() {
        viewModelScope.launch {
            authService.signOut()
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}

data class EmailVerificationUiState(
    val email: String = "",
    val user: FirebaseUser? = null,
    val isResending: Boolean = false,
    val isResendSuccessful: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
