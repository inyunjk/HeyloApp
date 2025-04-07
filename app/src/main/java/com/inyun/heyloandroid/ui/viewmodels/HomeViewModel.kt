package com.inyun.heyloandroid.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.inyun.heyloandroid.services.AuthService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HomeViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    private val authService = AuthService.getInstance(application)

    init {
        loadUserInfo()
    }

    private fun loadUserInfo() {
        val currentUser = authService.getCurrentUser()
        if (currentUser != null) {
            _uiState.value = _uiState.value.copy(
                displayName = currentUser.displayName ?: "User",
                email = currentUser.email ?: "",
                profileImageUrl = currentUser.photoUrl?.toString()
            )
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authService.signOut()
            _uiState.value = _uiState.value.copy(isSignedOut = true)
        }
    }
}

data class HomeUiState(
    val displayName: String = "",
    val email: String = "",
    val profileImageUrl: String? = null,
    val isSignedOut: Boolean = false
)
