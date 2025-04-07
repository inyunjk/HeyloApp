package com.inyun.heyloandroid.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.inyun.heyloandroid.R

@Composable
fun LoadingAnimation(
    modifier: Modifier = Modifier,
    size: Float = 150f
) {
    val infiniteTransition = rememberInfiniteTransition(label = "loadingTransition")

    // Rotation animation for the circle
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    // Pulse animation for the outer circle
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    // Fade animation for logo
    val logoAlpha by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "logoAlpha"
    )

    Box(
        modifier = modifier.size(size.dp),
        contentAlignment = Alignment.Center
    ) {
        // Pulse circle (behind the main circle)
        Canvas(
            modifier = Modifier
                .size(size.dp * pulseScale)
        ) {
            // Draw pulse circle
            drawCircle(
                color = Color.White.copy(alpha = 0.3f),
                radius = size / 2,
                style = Stroke(width = 8f, cap = StrokeCap.Round)
            )
        }

        // Main rotating circle
        Canvas(
            modifier = Modifier
                .size(size.dp)
                .rotate(rotation)
        ) {
            // Draw main circle
            drawCircle(
                color = Color.White,
                radius = size / 2,
                style = Stroke(width = 8f, cap = StrokeCap.Round)
            )
        }

        // Logo in the center (using Text instead of Image for the "H")
        androidx.compose.material3.Text(
            text = "H",
            color = Color.White,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .alpha(logoAlpha)
        )
    }
}
