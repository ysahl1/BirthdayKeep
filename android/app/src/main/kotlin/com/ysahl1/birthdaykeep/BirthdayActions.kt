package com.ysahl1.birthdaykeep

import android.app.PendingIntent
import android.content.Context
import android.content.Intent

// Einstieg in die App von Widgets, Schnelleinstellungen und App-Shortcuts
object BirthdayActions {
    const val EXTRA = "birthdaykeep_action"
    const val LIST = "list"
    const val ADD = "add"
    const val SEARCH = "search"

    fun intent(context: Context, action: String): Intent =
        Intent(context, MainActivity::class.java).apply {
            putExtra(EXTRA, action)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

    fun pendingIntent(context: Context, action: String): PendingIntent =
        PendingIntent.getActivity(
            context,
            action.hashCode(),
            intent(context, action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
}
