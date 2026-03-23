package com.example.joy_tv.streamengine.models

import com.example.joy_tv.streamengine.adapters.AppAdapter

sealed interface Show : AppAdapter.Item {
    var isFavorite: Boolean
}
