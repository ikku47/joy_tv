package com.example.joy_tv.streamengine

import android.content.Context
import android.util.Log
import com.example.joy_tv.BuildConfig
import com.example.joy_tv.streamengine.database.AppDatabase
import com.example.joy_tv.streamengine.extractors.Extractor
import com.example.joy_tv.streamengine.models.Video
import com.example.joy_tv.streamengine.providers.TmdbProvider
import com.example.joy_tv.streamengine.utils.DnsResolver
import com.example.joy_tv.streamengine.utils.UserPreferences
import com.example.joy_tv.streamengine.utils.format
import com.google.gson.*
import java.lang.reflect.Type
import java.util.Calendar
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class StreamEngine(private val scope: CoroutineScope) : MethodChannel.MethodCallHandler {

    companion object {
        lateinit var context: Context
    }

    private val gson = GsonBuilder()
        .registerTypeAdapter(Calendar::class.java, JsonSerializer<Calendar> { src, _, _ ->
            if (src == null) JsonNull.INSTANCE
            else JsonPrimitive(src.format("yyyy-MM-dd") ?: "")
        })
        .create()

    fun setup(context: Context, messenger: BinaryMessenger, scope: CoroutineScope) {
        Companion.context = context.applicationContext
        val channel = MethodChannel(messenger, "com.example.joy_tv.stream_engine")
        channel.setMethodCallHandler(this)

        try {
            UserPreferences.setup(Companion.context)
            DnsResolver.setDnsUrl(UserPreferences.dohProviderUrl)
            
            // Set values from build config
            UserPreferences.tmdbApiKey = BuildConfig.TMDB_API_KEY
            
            Log.i("StreamEngine", "Initialized successfully with TMDB Key: ${BuildConfig.TMDB_API_KEY.take(5)}...")
        } catch (e: Exception) {
            Log.e("StreamEngine", "Setup failed: ${e.message}")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
                    "get_home" -> {
                val language = call.argument<String>("language") ?: "en"
                val section = call.argument<String>("section")
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val home = withContext(Dispatchers.IO) { provider.getHome(section) }
                        val json = gson.toJson(home)
                        Log.i("StreamEngineDebug", "get_home Result Len: ${json.length}")
                        result.success(json)
                    } catch (e: Exception) {
                        Log.e("StreamEngineDebug", "get_home Error: ${e.message}", e)
                        result.error("PROVIDER_ERROR", e.message, e.stackTraceToString())
                    }
                }
            }
            "get_movies" -> {
                val language = call.argument<String>("language") ?: "en"
                val page = call.argument<Int>("page") ?: 1
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val movies = withContext(Dispatchers.IO) { provider.getMovies(page) }
                        result.success(gson.toJson(movies))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "get_tv_shows" -> {
                val language = call.argument<String>("language") ?: "en"
                val page = call.argument<Int>("page") ?: 1
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val shows = withContext(Dispatchers.IO) { provider.getTvShows(page) }
                        result.success(gson.toJson(shows))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "search" -> {
                val query = call.argument<String>("query") ?: ""
                val language = call.argument<String>("language") ?: "en"
                val page = call.argument<Int>("page") ?: 1
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val results = withContext(Dispatchers.IO) { provider.search(query, page) }
                        result.success(gson.toJson(results))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "get_movie_details" -> {
                val id = call.argument<String>("id") ?: return result.error("INVALID_ARG", "ID required", null)
                val language = call.argument<String>("language") ?: "en"
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val movie = withContext(Dispatchers.IO) { provider.getMovie(id) }
                        result.success(gson.toJson(movie))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "get_tv_show_details" -> {
                val id = call.argument<String>("id") ?: return result.error("INVALID_ARG", "ID required", null)
                val language = call.argument<String>("language") ?: "en"
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val tvShow = withContext(Dispatchers.IO) { provider.getTvShow(id) }
                        result.success(gson.toJson(tvShow))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "get_episodes" -> {
                val seasonId = call.argument<String>("seasonId") ?: return result.error("INVALID_ARG", "SeasonID required", null)
                val language = call.argument<String>("language") ?: "en"
                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val episodes = withContext(Dispatchers.IO) { provider.getEpisodesBySeason(seasonId) }
                        result.success(gson.toJson(episodes))
                    } catch (e: Exception) {
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "get_servers" -> {
                val id = call.argument<String>("id") ?: ""
                val type = call.argument<String>("type") ?: "movie"
                val language = call.argument<String>("language") ?: "en"

                scope.launch {
                    try {
                        val provider = TmdbProvider(language)
                        val videoType: Video.Type = if (type == "movie") {
                            val movie = withContext(Dispatchers.IO) { provider.getMovie(id) }
                            Video.Type.Movie(
                                id = movie.id,
                                title = movie.title,
                                releaseDate = movie.released?.format("yyyy-MM-dd") ?: "",
                                poster = movie.poster ?: "",
                                imdbId = movie.imdbId,
                            )
                        } else {
                            // For episodes, accept direct fields (avoids GSON Calendar issues)
                            val tvShowId  = call.argument<String>("tvShowId") ?: id
                            val seasonNum = call.argument<Int>("seasonNumber") ?: 1
                            val episodeNum = call.argument<Int>("episodeNumber") ?: 1
                            val episodeId  = call.argument<String>("episodeId") ?: ""

                            // Fetch TV show to get title/imdbId
                            val tvShow = withContext(Dispatchers.IO) { provider.getTvShow(tvShowId) }

                            val videoTvShow = Video.Type.Episode.TvShow(
                                id = tvShowId,
                                title = tvShow.title,
                                poster = tvShow.poster,
                                banner = tvShow.banner,
                                releaseDate = tvShow.released?.format("yyyy-MM-dd"),
                                imdbId = tvShow.imdbId,
                            )
                            val videoSeason = Video.Type.Episode.Season(
                                number = seasonNum,
                                title = null,
                            )
                            Video.Type.Episode(
                                id = episodeId,
                                number = episodeNum,
                                title = null,
                                poster = null,
                                overview = null,
                                tvShow = videoTvShow,
                                season = videoSeason,
                            )
                        }

                        val servers = withContext(Dispatchers.IO) { provider.getServers(id, videoType) }
                        result.success(gson.toJson(servers))
                    } catch (e: Exception) {
                        Log.e("StreamEngine", "get_servers error: ${e.message}", e)
                        result.error("PROVIDER_ERROR", e.message, null)
                    }
                }
            }
            "extract_video" -> {
                val serverJson = call.argument<String>("serverJson") ?: ""
                val language = call.argument<String>("language") ?: "en"
                scope.launch {
                    try {
                        val server = gson.fromJson(serverJson, Video.Server::class.java)
                        val provider = TmdbProvider(language)
                        val video = withContext(Dispatchers.IO) { provider.getVideo(server) }
                        result.success(gson.toJson(video))
                    } catch (e: Exception) {
                        Log.e("StreamEngine", "extract_video error: ${e.message}", e)
                        result.error("EXTRACTOR_ERROR", e.message, null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }
}
