class TmdbConfig {
  static const homeGenres = [
    {'id': null, 'name': 'All'},
    {'id': 28, 'name': 'Action'},
    {'id': 12, 'name': 'Adventure'},
    {'id': 16, 'name': 'Animation'},
    {'id': 35, 'name': 'Comedy'},
    {'id': 80, 'name': 'Crime'},
    {'id': 99, 'name': 'Documentary'},
    {'id': 18, 'name': 'Drama'},
    {'id': 10751, 'name': 'Family'},
    {'id': 14, 'name': 'Fantasy'},
    {'id': 36, 'name': 'History'},
    {'id': 27, 'name': 'Horror'},
    {'id': 10402, 'name': 'Music'},
    {'id': 9648, 'name': 'Mystery'},
    {'id': 10749, 'name': 'Romance'},
    {'id': 878, 'name': 'Science Fiction'},
    {'id': 10770, 'name': 'TV Movie'},
    {'id': 53, 'name': 'Thriller'},
    {'id': 10752, 'name': 'War'},
    {'id': 37, 'name': 'Western'}
  ];

  // Watch Provider IDs
  static const netflixId = 8;
  static const disneyPlusId = 337;
  static const appleTvPlusId = 2;
  static const amazonPrimeId = 119; // Amazon Prime Video
  static const maxId = 1899; // Formerly HBO Max
  static const paramountPlusId = 531;
  static const peacockId = 386;
  static const huluId = 15;
  static const crunchyrollId = 283;
  static const tubiId = 73;

  static const rowConfig = {
    'home': [
      {'title': 'Trending This Week', 'endpoint': '/trending/all/week', 'icon': 'Flame'},
      {'title': 'Popular Movies', 'endpoint': '/movie/popular', 'icon': 'Clapperboard'},
      {'title': 'Popular TV Shows', 'endpoint': '/tv/popular', 'icon': 'Tv'},
      {'title': 'Netflix Originals', 'endpoint': '/discover/movie?with_watch_providers=$netflixId&watch_region=US', 'icon': 'Play'},
      {'title': 'Top Rated Movies', 'endpoint': '/movie/top_rated', 'icon': 'Star'},
    ],
    'movies': [
      {'title': 'Trending Movies', 'endpoint': '/trending/movie/week', 'icon': 'Flame'},
      {'title': 'Popular on Netflix', 'endpoint': '/discover/movie?with_watch_providers=$netflixId&watch_region=US', 'icon': 'Movie'},
      {'title': 'Disney+ Favorites', 'endpoint': '/discover/movie?with_watch_providers=$disneyPlusId&watch_region=US', 'icon': 'Star'},
      {'title': 'Apple TV+ Originals', 'endpoint': '/discover/movie?with_watch_providers=$appleTvPlusId&watch_region=US', 'icon': 'Laptop'},
      {'title': 'Max Originals', 'endpoint': '/discover/movie?with_watch_providers=$maxId&watch_region=US', 'icon': 'Tv'},
      {'title': 'Amazon Prime', 'endpoint': '/discover/movie?with_watch_providers=$amazonPrimeId&watch_region=US', 'icon': 'ShoppingBag'},
      {'title': 'Paramount+', 'endpoint': '/discover/movie?with_watch_providers=$paramountPlusId&watch_region=US', 'icon': 'Video'},
      {'title': 'Upcoming', 'endpoint': '/movie/upcoming', 'icon': 'Calendar'},
      {'title': 'Top Rated', 'endpoint': '/movie/top_rated', 'icon': 'Star'},
    ],
    'series': [
      {'title': 'Trending Series', 'endpoint': '/trending/tv/week', 'icon': 'Flame'},
      {'title': 'Popular on Netflix', 'endpoint': '/discover/tv?with_watch_providers=$netflixId&watch_region=US', 'icon': 'Tv'},
      {'title': 'Disney+ Originals', 'endpoint': '/discover/tv?with_watch_providers=$disneyPlusId&watch_region=US', 'icon': 'Star'},
      {'title': 'Max Hits', 'endpoint': '/discover/tv?with_watch_providers=$maxId&watch_region=US', 'icon': 'Monitor'},
      {'title': 'Apple TV+ Series', 'endpoint': '/discover/tv?with_watch_providers=$appleTvPlusId&watch_region=US', 'icon': 'Laptop'},
      {'title': 'Hulu Originals', 'endpoint': '/discover/tv?with_watch_providers=$huluId&watch_region=US', 'icon': 'MonitorPlay'},
      {'title': 'Anime on Crunchyroll', 'endpoint': '/discover/tv?with_watch_providers=$crunchyrollId&watch_region=US', 'icon': 'Ghost'},
      {'title': 'Popular Shows', 'endpoint': '/tv/popular', 'icon': 'Tv'},
      {'title': 'Top Rated', 'endpoint': '/tv/top_rated', 'icon': 'Star'},
    ],
  };

  static const languages = [
    {'id': 'en', 'name': 'English'},
    {'id': 'hi', 'name': 'हिन्दी'},
    {'id': 'es', 'name': 'Español'},
    {'id': 'fr', 'name': 'Français'},
    {'id': 'ja', 'name': '日本語'},
    {'id': 'ko', 'name': '한국어'},
    {'id': 'zh', 'name': '中文'},
    {'id': 'ar', 'name': 'العربية'},
    {'id': 'ru', 'name': 'Русский'},
    {'id': 'pt', 'name': 'Português'},
    {'id': 'de', 'name': 'Deutsch'},
    {'id': 'it', 'name': 'Italiano'},
    {'id': 'te', 'name': 'తెలుగు'},
    {'id': 'ta', 'name': 'தமிழ்'},
    {'id': 'bn', 'name': 'বাংলা'},
    {'id': 'ml', 'name': 'മലയാളം'},
    {'id': 'kn', 'name': 'ಕನ್ನಡ'},
    {'id': 'mr', 'name': 'मराठी'},
    {'id': 'gu', 'name': 'ગુજરાતી'},
    {'id': 'pa', 'name': 'ਪੰਜਾਬੀ'},
    {'id': 'ur', 'name': 'اردو'}
  ];
}
