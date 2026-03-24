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

  static const rowConfig = {
    'home': [
      {'title': 'Trending This Week', 'endpoint': '/trending/all/week', 'icon': 'Flame'},
      {'title': 'Popular Movies', 'endpoint': '/movie/popular', 'icon': 'Clapperboard'},
      {'title': 'Popular TV Shows', 'endpoint': '/tv/popular', 'icon': 'Tv'},
      {'title': 'Top Rated Movies', 'endpoint': '/movie/top_rated', 'icon': 'Star'},
      {'title': 'Now Playing', 'endpoint': '/movie/now_playing', 'icon': 'Theater'},
      {'title': 'Airing Today', 'endpoint': '/tv/airing_today', 'icon': 'Radio'},
      {'title': 'Top Rated TV', 'endpoint': '/tv/top_rated', 'icon': 'Trophy'},
      {'title': 'Upcoming Movies', 'endpoint': '/movie/upcoming', 'icon': 'Calendar'},
    ],
    'movies': [
      {'title': 'Popular Movies', 'endpoint': '/movie/popular', 'icon': 'Clapperboard'},
      {'title': 'Top Rated', 'endpoint': '/movie/top_rated', 'icon': 'Star'},
      {'title': 'Now Playing', 'endpoint': '/movie/now_playing', 'icon': 'Theater'},
      {'title': 'Upcoming', 'endpoint': '/movie/upcoming', 'icon': 'Calendar'},
    ],
    'series': [
      {'title': 'Popular Shows', 'endpoint': '/tv/popular', 'icon': 'Tv'},
      {'title': 'Top Rated', 'endpoint': '/tv/top_rated', 'icon': 'Star'},
      {'title': 'Airing Today', 'endpoint': '/tv/airing_today', 'icon': 'Radio'},
      {'title': 'On The Air', 'endpoint': '/tv/on_the_air', 'icon': 'RadioTower'},
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
