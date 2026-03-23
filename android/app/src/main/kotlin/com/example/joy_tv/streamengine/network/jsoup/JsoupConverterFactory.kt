package com.example.joy_tv.streamengine.network.jsoup

import okhttp3.ResponseBody
import org.jsoup.nodes.Document
import retrofit2.Converter
import retrofit2.Retrofit
import java.lang.reflect.Type

class JsoupConverterFactory : Converter.Factory() {

    override fun responseBodyConverter(
        type: Type,
        annotations: Array<Annotation>,
        retrofit: Retrofit
    ): Converter<ResponseBody, *>? {
        return if (type == Document::class.java) JsoupConverter(retrofit.baseUrl().toString()) else null
    }

    companion object {
        fun create(): JsoupConverterFactory {
            return JsoupConverterFactory()
        }
    }
}