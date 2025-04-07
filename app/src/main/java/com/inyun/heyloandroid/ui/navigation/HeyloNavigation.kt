package com.inyun.heyloandroid.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.inyun.heyloandroid.ui.screens.HomeScreen
import com.inyun.heyloandroid.ui.screens.PendingEmailVerificationScreen
import com.inyun.heyloandroid.ui.screens.PreHomeScreen
import com.inyun.heyloandroid.ui.screens.SignInScreen
import com.inyun.heyloandroid.ui.screens.SignUpScreen

sealed class Screen(val route: String) {
    object SignIn : Screen("signIn")
    object SignUp : Screen("signUp")
    object PendingEmailVerification : Screen("pendingEmailVerification")
    object PreHome : Screen("preHome")
    object Home : Screen("home")
}

@Composable
fun HeyloNavigation(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.SignIn.route
) {

    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        composable(Screen.SignIn.route) {
            SignInScreen(
                onNavigateToSignUp = {
                    navController.navigate(Screen.SignUp.route)
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.SignIn.route) { inclusive = true }
                    }
                },
                onNavigateToEmailVerification = {
                    navController.navigate(Screen.PendingEmailVerification.route)
                },
                navController = navController
            )
        }

        composable(Screen.SignUp.route) {
            SignUpScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToEmailVerification = {
                    // Add logging to debug navigation
                    android.util.Log.d("HeyloNavigation", "Navigating from SignUp to PendingEmailVerification")
                    navController.navigate(Screen.PendingEmailVerification.route) {
                        popUpTo(Screen.SignUp.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.PendingEmailVerification.route) {
            PendingEmailVerificationScreen(
                onNavigateToSignIn = {
                    navController.navigate(Screen.SignIn.route) {
                        popUpTo(Screen.PendingEmailVerification.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.PreHome.route) {
            PreHomeScreen(
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.PreHome.route) { inclusive = true }
                    }
                },
                onNavigateToEmailVerification = {
                    navController.navigate(Screen.PendingEmailVerification.route) {
                        popUpTo(Screen.PreHome.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToSignIn = {
                    navController.navigate(Screen.SignIn.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }
    }
}


