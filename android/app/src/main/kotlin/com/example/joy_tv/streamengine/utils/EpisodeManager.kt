package com.example.joy_tv.streamengine.utils

import android.content.Context
import com.example.joy_tv.streamengine.database.AppDatabase
import com.example.joy_tv.streamengine.database.dao.EpisodeDao
import com.example.joy_tv.streamengine.models.Video
import com.example.joy_tv.streamengine.models.Video.Type.Episode
import kotlin.collections.map
import com.example.joy_tv.streamengine.utils.format

object EpisodeManager {
    private val episodes = mutableListOf<Episode>()
    var currentIndex = 0
        private set

    fun addEpisodes(list: List<Episode>) {
        episodes.clear()
        episodes.addAll(list)
        currentIndex = 0
    }

    fun addEpisodesFromDb(type: Video.Type.Episode, database: AppDatabase){
        val tvShowId = type.tvShow.id
        val seasonNumber = type.season.number
        val episodesFromDb = database.episodeDao().getByTvShowIdAndSeasonNumber(tvShowId, seasonNumber)
        if (!episodesFromDb.isEmpty()){
            addEpisodes(convertToVideoTypeEpisodes(episodesFromDb, database, seasonNumber));

        }
    }
    fun clearEpisodes(){
        episodes.clear()
        currentIndex = 0
    }
    fun setCurrentEpisode(episode: Episode) {
        currentIndex = episodes.indexOfFirst { it.id == episode.id }
    }

    fun getCurrentEpisode(): Episode? =
        episodes.getOrNull(currentIndex)

    fun getNextEpisode(): Episode? {
        if (currentIndex + 1 < episodes.size) {
            currentIndex++
            return episodes[currentIndex]
        }
        return null
    }
    fun getPreviousEpisode(): Episode? {
        if (currentIndex -1 >= 0){
            currentIndex--
            return episodes[currentIndex]
        }
        return null
    }
    fun hasPreviousEpisode(): Boolean {
        return currentIndex > 0
    }

    fun hasNextEpisode(): Boolean {
        return currentIndex < episodes.size - 1
    }

    fun listIsEmpty(episode: Episode): Boolean{
        return episodes.isEmpty() || return episodes.indexOf(episode) == -1
    }

    fun convertToVideoTypeEpisodes(episodes: List<com.example.joy_tv.streamengine.models.Episode>, database: AppDatabase, seasonNumber: Int): List<Episode> {
        val videoEpisodes = episodes.map { ep ->
            val seasonId = ep.season?.id ?: ""
            val tvShowId = ep.tvShow?.id ?: ""
            val seasonFromDb = database.seasonDao().getById(seasonId)
            val tvShowFromDb = database.tvShowDao().getById(tvShowId)
            Episode(
                id = ep.id,
                number = ep.number,
                title = ep.title,
                poster = ep.poster,
                overview = ep.overview,
                tvShow = Episode.TvShow(
                    id = tvShowId,
                    title = tvShowFromDb?.title ?: "",
                    poster = tvShowFromDb?.poster ?: ep.tvShow?.poster,
                    banner = tvShowFromDb?.banner ?: ep.tvShow?.banner,
                    releaseDate = tvShowFromDb?.released?.format("yyyy-MM-dd") ?: ep.tvShow?.released?.format("yyyy-MM-dd"),
                    imdbId = tvShowFromDb?.imdbId ?: ep.tvShow?.imdbId
                ),
                season = Episode.Season(
                    number = seasonFromDb?.number ?: seasonNumber,
                    title = seasonFromDb?.title ?: ep.season?.title
                )
            )
        }
        return videoEpisodes
    }



}
