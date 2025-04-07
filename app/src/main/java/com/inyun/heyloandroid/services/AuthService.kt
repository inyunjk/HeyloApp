package com.inyun.heyloandroid.services

import android.content.Context
import android.net.Uri
import android.util.Base64
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.functions.ktx.functions
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.tasks.await
import org.json.JSONObject
import java.io.InputStream

/**
 * Service for handling Firebase Authentication operations
 */
class AuthService private constructor(private val context: Context) {

    private val auth = FirebaseAuth.getInstance()
    private val functions = Firebase.functions

    companion object {
        private var instance: AuthService? = null

        fun getInstance(context: Context): AuthService {
            if (instance == null) {
                instance = AuthService(context.applicationContext)
            }
            return instance!!
        }
    }

    /**
     * Sign in with email and password using secure backend function
     */
    suspend fun signIn(email: String, password: String): Result<FirebaseUser> {
        return try {
            // Create data for the function call
            val data = hashMapOf(
                "email" to email,
                "password" to password
            )

            // Call the secure backend function
            val result = functions.getHttpsCallable("secureSignIn")
                .call(data)
                .await()

            // Parse the result
            val resultData = result.data as? Map<String, Any>
            val success = resultData?.get("success") as? Boolean ?: false

            if (success) {
                // Sign in directly with email and password
                val authResult = auth.signInWithEmailAndPassword(email, password).await()
                authResult.user?.let {
                    Result.success(it)
                } ?: Result.failure(Exception("User not found"))
            } else {
                val errorMessage = resultData?.get("error") as? String ?: "Unknown error"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            // Check if it's a rate limiting error
            if (e.message?.contains("too many requests") == true ||
                e.message?.contains("rate limit") == true) {
                Result.failure(Exception("Too many sign-in attempts. Please try again later."))
            } else {
                Result.failure(e)
            }
        }
    }

    /**
     * Reset rate limiters (development only)
     */
    suspend fun resetRateLimiters(): Result<Unit> {
        return try {
            val result = functions.getHttpsCallable("devResetRateLimitersHttp")
                .call()
                .await()

            val resultData = result.data as? Map<String, Any>
            val success = resultData?.get("success") as? Boolean ?: false

            if (success) {
                Result.success(Unit)
            } else {
                val errorMessage = resultData?.get("error") as? String ?: "Unknown error"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Sign up with email, password, display name, and optional profile image using secure backend function
     */
    suspend fun signUp(
        email: String,
        password: String,
        displayName: String,
        profileImageUri: Uri?
    ): Result<FirebaseUser> {
        return try {
            // Create data for the function call
            val data = mutableMapOf(
                "email" to email,
                "password" to password,
                "displayName" to displayName
            )

            // If profile image is provided, convert it to base64
            if (profileImageUri != null) {
                try {
                    android.util.Log.d("AuthService", "Processing profile image: $profileImageUri")
                    val inputStream = context.contentResolver.openInputStream(profileImageUri)
                    if (inputStream != null) {
                        val bytes = inputStream.readBytes()
                        inputStream.close()
                        val base64Image = android.util.Base64.encodeToString(bytes, android.util.Base64.DEFAULT)
                        data["profileImageBase64"] = "data:image/jpeg;base64,$base64Image"
                        android.util.Log.d("AuthService", "Profile image converted to base64 (${base64Image.length} chars)")
                    } else {
                        android.util.Log.e("AuthService", "Failed to open input stream for profile image")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("AuthService", "Error processing profile image: ${e.message}")
                }
            }

            // Log the data being sent
            android.util.Log.d("AuthService", "Sending sign up data: $data")

            // Call the secure backend function
            android.util.Log.d("AuthService", "Calling secureSignUp function")
            try {
                // Check if we're running in an emulator or test environment
                val isEmulator = android.os.Build.FINGERPRINT.contains("generic") ||
                        android.os.Build.FINGERPRINT.contains("sdk_gphone") ||
                        android.os.Build.MODEL.contains("sdk") ||
                        android.os.Build.MODEL.contains("Emulator") ||
                        android.os.Build.MODEL.contains("Android SDK")

                if (isEmulator) {
                    // For emulator testing, create the user directly with Firebase Auth
                    android.util.Log.d("AuthService", "Running in emulator, using direct Firebase Auth")
                    try {
                        // Create user with email and password
                        val authResult = auth.createUserWithEmailAndPassword(email, password).await()
                        val user = authResult.user ?: return Result.failure(Exception("User not created"))

                        // Update display name
                        val profileUpdates = com.google.firebase.auth.UserProfileChangeRequest.Builder()
                            .setDisplayName(displayName)
                            .build()
                        user.updateProfile(profileUpdates).await()

                        // Send email verification
                        user.sendEmailVerification().await()
                        android.util.Log.d("AuthService", "User created and verification email sent")

                        // Return success
                        return Result.success(user)
                    } catch (e: Exception) {
                        android.util.Log.e("AuthService", "Error creating user directly: ${e.message}")
                        return Result.failure(e)
                    }
                } else {
                    // Normal flow using Firebase Functions
                    val result = functions.getHttpsCallable("secureSignUp")
                        .call(data)
                        .await()

                    // Parse the result
                    android.util.Log.d("AuthService", "Raw result data: ${result.data}")
                    val resultData = result.data as? Map<String, Any>
                    android.util.Log.d("AuthService", "Sign up result: $resultData")
                    val success = resultData?.get("success") as? Boolean ?: false
                    android.util.Log.d("AuthService", "Success value: $success")

                    if (success) {
                        // Sign in directly with email and password
                        android.util.Log.d("AuthService", "Signing in with email and password")
                        try {
                            val authResult = auth.signInWithEmailAndPassword(email, password).await()
                            val user = authResult.user ?: return Result.failure(Exception("User not created"))
                            android.util.Log.d("AuthService", "Sign in successful, user: $user")

                            // Check if we need to send verification email from client
                            val emailVerificationLink = resultData["emailVerificationLink"] as? String
                            android.util.Log.d("AuthService", "Email verification link: $emailVerificationLink")
                            if (emailVerificationLink == "CLIENT_SEND_VERIFICATION") {
                                android.util.Log.d("AuthService", "Sending email verification from client")
                                user.sendEmailVerification().await()
                                android.util.Log.d("AuthService", "Email verification sent successfully")
                            }

                            // Get the user from the auth instance
                            val currentUser = auth.currentUser
                            if (currentUser != null) {
                                return Result.success(currentUser)
                            } else {
                                return Result.failure(Exception("Failed to get current user after sign-up"))
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("AuthService", "Error signing in: ${e.message}")
                            return Result.failure(e)
                        }
                    } else {
                        val errorMessage = resultData?.get("error") as? String ?: "Unknown error"
                        return Result.failure(Exception(errorMessage))
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("AuthService", "Error calling secureSignUp: ${e.message}")
                android.util.Log.e("AuthService", "Error details: ${e.stackTraceToString()}")

                // If we get a network error, try to create the user directly
                if (e.message?.contains("UnknownHostException") == true ||
                    e.message?.contains("No address associated with hostname") == true) {
                    android.util.Log.d("AuthService", "Network error, trying direct Firebase Auth")
                    try {
                        // Create user with email and password
                        val authResult = auth.createUserWithEmailAndPassword(email, password).await()
                        val user = authResult.user ?: return Result.failure(Exception("User not created"))

                        // Update display name
                        val profileUpdates = com.google.firebase.auth.UserProfileChangeRequest.Builder()
                            .setDisplayName(displayName)
                            .build()
                        user.updateProfile(profileUpdates).await()

                        // Send email verification
                        user.sendEmailVerification().await()
                        android.util.Log.d("AuthService", "User created and verification email sent")

                        // Return success
                        return Result.success(user)
                    } catch (e2: Exception) {
                        android.util.Log.e("AuthService", "Error creating user directly: ${e2.message}")
                        return Result.failure(e2)
                    }
                }

                return Result.failure(e)
            }


        } catch (e: Exception) {
            // Check if it's a rate limiting error
            if (e.message?.contains("too many requests") == true ||
                e.message?.contains("rate limit") == true) {
                Result.failure(Exception("Too many sign-up attempts. Please try again later."))
            } else {
                Result.failure(e)
            }
        }
    }

    // Removed bitmapToBase64 method as it's no longer needed

    /**
     * Sign out the current user using secure backend function
     */
    suspend fun signOut(): Result<Unit> {
        return try {
            // First sign out locally to ensure the user is signed out even if the backend call fails
            auth.signOut()

            // Then call the backend function (but don't wait for it)
            functions.getHttpsCallable("secureSignOut").call()

            Result.success(Unit)
        } catch (e: Exception) {
            // Still return success since we've signed out locally
            Result.success(Unit)
        }
    }

    /**
     * Send email verification to the user using secure backend function
     */
    suspend fun sendEmailVerification(): Result<String> {
        return try {
            val result = functions.getHttpsCallable("resendEmailVerification")
                .call()
                .await()

            val resultData = result.data as? Map<String, Any>
            val success = resultData?.get("success") as? Boolean ?: false

            if (success) {
                val emailVerificationLink = resultData["emailVerificationLink"] as? String

                // Check if we need to send verification email from client
                if (emailVerificationLink == "CLIENT_SEND_VERIFICATION") {
                    val user = auth.currentUser
                    if (user != null) {
                        user.sendEmailVerification().await()
                        Result.success("Verification email sent. Please check your inbox.")
                    } else {
                        Result.failure(Exception("No user is signed in"))
                    }
                } else {
                    Result.success(emailVerificationLink ?: "")
                }
            } else {
                val errorMessage = resultData?.get("error") as? String ?: "Unknown error"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if the current user's email is verified using secure backend function
     */
    suspend fun checkEmailVerification(): Result<Boolean> {
        return try {
            // First check locally
            val currentUser = auth.currentUser
            currentUser?.reload()?.await()

            if (currentUser?.isEmailVerified == true) {
                return Result.success(true)
            }

            // If not verified locally, check with the backend
            val result = functions.getHttpsCallable("checkEmailVerification")
                .call()
                .await()

            val resultData = result.data as? Map<String, Any>
            val success = resultData?.get("success") as? Boolean ?: false

            if (success) {
                val isVerified = resultData["emailVerified"] as? Boolean ?: false
                Result.success(isVerified)
            } else {
                val errorMessage = resultData?.get("error") as? String ?: "Unknown error"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get the current user
     */
    fun getCurrentUser(): FirebaseUser? {
        return auth.currentUser
    }
}
