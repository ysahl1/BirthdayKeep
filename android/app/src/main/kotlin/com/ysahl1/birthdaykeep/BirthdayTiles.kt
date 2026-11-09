package com.ysahl1.birthdaykeep

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

// Kacheln für die Schnelleinstellungen (Kontrollzentrum)
abstract class BirthdayTile(private val action: String) : TileService() {
    override fun onStartListening() {
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        if (isLocked) unlockAndRun { open() } else open()
    }

    @Suppress("DEPRECATION")
    private fun open() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(BirthdayActions.pendingIntent(this, action))
        } else {
            startActivityAndCollapse(BirthdayActions.intent(this, action))
        }
    }
}

class ListTileService : BirthdayTile(BirthdayActions.LIST)

class AddTileService : BirthdayTile(BirthdayActions.ADD)
