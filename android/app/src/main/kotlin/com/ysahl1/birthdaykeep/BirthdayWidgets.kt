package com.ysahl1.birthdaykeep

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlin.math.min
import org.json.JSONArray

private const val ROWS = 3
private val NAME_IDS = intArrayOf(R.id.widget_name_1, R.id.widget_name_2, R.id.widget_name_3)
private val DAYS_IDS = intArrayOf(R.id.widget_days_1, R.id.widget_days_2, R.id.widget_days_3)
private val DATE_IDS = intArrayOf(R.id.widget_date_1, R.id.widget_date_2, R.id.widget_date_3)
private val ROW_IDS = intArrayOf(R.id.widget_row_1, R.id.widget_row_2, R.id.widget_row_3)

private data class Upcoming(val name: String, val days: Long, val date: LocalDate)

// Liest direkt aus den Einstellungen, die auch die Flutter-App verwendet
private class WidgetData(context: Context) {
    private val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    val locked: Boolean
        get() {
            val mode = (prefs.all["flutter.lock_mode"] as? Number)?.toInt()
            return if (mode != null) mode != 0 else prefs.getBoolean("flutter.biometric_enabled", false)
        }

    val language: String? get() = prefs.getString("flutter.language", null)

    val datePattern: String
        get() = when (prefs.getString("flutter.dateStyle", null)) {
            "dayMonthYearDot", "dayMonthShortYearDot" -> "%1\$02d.%2\$02d."
            "dayMonthYearDash" -> "%1\$02d-%2\$02d"
            "monthDayYearSlash", "monthDayShortYearSlash" -> "%2\$02d/%1\$02d"
            "yearMonthDayDash" -> "%2\$02d-%1\$02d"
            "yearMonthDaySlash" -> "%2\$02d/%1\$02d"
            else -> "%1\$02d/%2\$02d"
        }

    fun upcoming(today: LocalDate): List<Upcoming> {
        val raw = prefs.getString("flutter.birthday_entries", null) ?: return emptyList()
        val entries = try {
            JSONArray(raw)
        } catch (e: org.json.JSONException) {
            return emptyList()
        }
        return (0 until entries.length()).map { index ->
            val entry = entries.getJSONObject(index)
            val birthday = entry.getString("birthday")
            val next = nextOccurrence(
                birthday.substring(5, 7).toInt(),
                birthday.substring(8, 10).toInt(),
                today,
            )
            Upcoming(entry.getString("name"), ChronoUnit.DAYS.between(today, next), next)
        }.sortedBy { it.days }.take(ROWS)
    }

    // Wer am 29. Februar geboren ist, erscheint sonst am 28., wie in der App
    private fun nextOccurrence(month: Int, day: Int, today: LocalDate): LocalDate {
        fun inYear(year: Int) = LocalDate.of(year, month, min(day, YearMonth.of(year, month).lengthOfMonth()))
        val thisYear = inYear(today.year)
        return if (thisYear.isBefore(today)) inYear(today.year + 1) else thisYear
    }
}

abstract class BirthdayWidget(private val layout: Int, private val showDate: Boolean) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { manager.updateAppWidget(it, buildViews(context)) }
    }

    private fun buildViews(context: Context): RemoteViews {
        val data = WidgetData(context)
        val text = localized(context, data.language)
        val views = RemoteViews(context.packageName, layout)

        views.setOnClickPendingIntent(R.id.widget_root, BirthdayActions.pendingIntent(context, BirthdayActions.LIST))
        views.setOnClickPendingIntent(R.id.widget_add, BirthdayActions.pendingIntent(context, BirthdayActions.ADD))
        views.setOnClickPendingIntent(R.id.widget_search, BirthdayActions.pendingIntent(context, BirthdayActions.SEARCH))

        // Bei aktiver Sperre gehören keine Namen auf den Startbildschirm
        val upcoming = if (data.locked) emptyList() else data.upcoming(LocalDate.now())
        val message = when {
            data.locked -> text.getString(R.string.widget_locked)
            upcoming.isEmpty() -> text.getString(R.string.widget_empty)
            else -> null
        }
        views.setViewVisibility(R.id.widget_message, if (message == null) View.GONE else View.VISIBLE)
        views.setTextViewText(R.id.widget_message, message ?: "")

        for (row in 0 until ROWS) {
            val item = upcoming.getOrNull(row)
            views.setViewVisibility(ROW_IDS[row], if (item == null) View.GONE else View.VISIBLE)
            if (item == null) continue
            views.setTextViewText(NAME_IDS[row], item.name)
            views.setTextViewText(DAYS_IDS[row], daysText(text, item.days))
            if (showDate) {
                views.setTextViewText(
                    DATE_IDS[row],
                    String.format(Locale.ROOT, data.datePattern, item.date.dayOfMonth, item.date.monthValue),
                )
            }
        }
        return views
    }

    private fun daysText(text: Context, days: Long): String = when (days) {
        0L -> text.getString(R.string.widget_today)
        1L -> text.getString(R.string.widget_tomorrow)
        else -> text.getString(R.string.widget_in_days, days)
    }

    private fun localized(context: Context, language: String?): Context {
        if (language == null) return context
        val config = Configuration(context.resources.configuration)
        config.setLocale(Locale(language))
        return context.createConfigurationContext(config)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            listOf(BirthdayWidgetSmall() to BirthdayWidgetSmall::class.java, BirthdayWidgetWide() to BirthdayWidgetWide::class.java)
                .forEach { (widget, type) ->
                    widget.onUpdate(context, manager, manager.getAppWidgetIds(ComponentName(context, type)))
                }
        }
    }
}

class BirthdayWidgetSmall : BirthdayWidget(R.layout.widget_small, showDate = false)

class BirthdayWidgetWide : BirthdayWidget(R.layout.widget_wide, showDate = true)
