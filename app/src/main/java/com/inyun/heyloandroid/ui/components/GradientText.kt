package com.inyun.heyloandroid.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier

import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Text
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import com.inyun.heyloandroid.ui.theme.GradientBlue
import com.inyun.heyloandroid.ui.theme.GradientGold
import com.inyun.heyloandroid.ui.theme.GradientGreen
import com.inyun.heyloandroid.ui.theme.GradientOrange
import com.inyun.heyloandroid.ui.theme.GradientPink
import com.inyun.heyloandroid.ui.theme.GradientPurple
import com.inyun.heyloandroid.ui.theme.GradientRed

@Composable
fun GradientText(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 48.sp,
    fontWeight: FontWeight = FontWeight.Bold,
    animated: Boolean = true
) {
    val gradientColors = listOf(
        GradientPink,
        GradientOrange,
        GradientGold,
        GradientGreen,
        GradientBlue,
        GradientPurple,
        GradientRed,
        GradientPink
    )

    val infiniteTransition = rememberInfiniteTransition(label = "gradientTransition")
    val offset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(10000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "gradientOffset"
    )

    val tiltX by infiniteTransition.animateFloat(
        initialValue = -0.02f,
        targetValue = 0.02f,
        animationSpec = infiniteRepeatable(
            animation = tween(5000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "tiltX"
    )

    val tiltY by infiniteTransition.animateFloat(
        initialValue = -0.01f,
        targetValue = 0.01f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "tiltY"
    )

    val brush = remember(offset) {
        Brush.linearGradient(
            colors = gradientColors,
            // Shift the gradient based on the offset
            start = androidx.compose.ui.geometry.Offset(offset, 0f),
            end = androidx.compose.ui.geometry.Offset(offset + 1f, 0f)
        )
    }


    // Use a custom text style with the gradient brush
    val gradientTextStyle = TextStyle(
        fontSize = fontSize,
        fontWeight = fontWeight,
        brush = brush
    )

    // Use the Text composable with the brush directly
    androidx.compose.material3.Text(
        text = text,
        modifier = modifier,
        style = gradientTextStyle
    )
}

@Composable
fun GradientSpanText(
    text: String,
    gradientText: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 16.sp,
    fontWeight: FontWeight = FontWeight.Normal,
    color: Color = Color.LightGray,
    animated: Boolean = true,
    onTextLayout: (TextLayoutResult) -> Unit = {}
) {
    val fullText = text
    val startIndex = fullText.indexOf(gradientText)

    if (startIndex == -1) {
        // If the gradient text is not found, just display the full text
        Text(
            text = text,
            modifier = modifier,
            style = TextStyle(
                fontSize = fontSize,
                fontWeight = fontWeight,
                color = color
            ),
            onTextLayout = onTextLayout
        )
        return
    }

    val beforeText = fullText.substring(0, startIndex)
    val afterText = fullText.substring(startIndex + gradientText.length)

    Row(
        modifier = modifier
    ) {
        if (beforeText.isNotEmpty()) {
            Text(
                text = beforeText,
                style = TextStyle(
                    fontSize = fontSize,
                    fontWeight = fontWeight,
                    color = color
                )
            )
        }

        GradientText(
            text = gradientText,
            fontSize = fontSize,
            fontWeight = fontWeight,
            animated = animated,
            modifier = Modifier
        )

        if (afterText.isNotEmpty()) {
            Text(
                text = afterText,
                style = TextStyle(
                    fontSize = fontSize,
                    fontWeight = fontWeight,
                    color = color
                )
            )
        }
    }
}


