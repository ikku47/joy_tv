package com.example.joy_tv.streamengine.adapters

import java.io.Serializable

abstract class AppAdapter {

    interface Item : Serializable {
        var itemType: Type
    }

    enum class Type {
        MOVIE,
        TV_SHOW,
        SEASON,
        EPISODE,
        PEOPLE,
        GENRE,
        CATEGORY,
        SERVER,
        SUBTITLE,
        UNKNOWN
    }
}