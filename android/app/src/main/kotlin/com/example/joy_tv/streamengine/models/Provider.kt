package com.example.joy_tv.streamengine.models

import com.example.joy_tv.streamengine.adapters.AppAdapter

open class Provider(
    val name: String,
    val logo: String,
    val language: String,

    val provider: com.example.joy_tv.streamengine.providers.Provider,
) : AppAdapter.Item {


    override lateinit var itemType: AppAdapter.Type
}