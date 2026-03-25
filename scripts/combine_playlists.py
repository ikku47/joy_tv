import json
import os
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

# ====================== PATHS ======================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
PLAYLISTS_JSON = os.path.join(PROJECT_ROOT, 'assets', 'playlists.json')
OUTPUT_M3U8 = os.path.join(PROJECT_ROOT, 'assets', 'default_playlist.m3u8')

# ====================== CATEGORY KEYWORDS ======================
# Enhanced CATEGORY_KEYWORDS with more comprehensive coverage
CATEGORY_KEYWORDS = {
    # Main Categories
    "Movies": [
        "movie", "movies", "cinema", "film", "vod", "кинозал", "kino", "filmrise", "cine",
        "filmax", "cinebox", "movieplex", "hollywood", "bollywood", "cinemax", "hbo",
        "paramount", "universal", "warner", "miramax", "starz", "showtime", "m4:", "m4:", "sky cinema",
        "cinevault", "film4", "tcm", "turner classic", "cine+", "cinema", "movies!", "film+",
        "cinebox", "moviedome", "movie sphere", "moviesphere", "movie music", "movietoper",
        "filmy", "film world", "cinema one", "cinecanal", "goldmines", "zee cinema", "star gold",
        "sony max", "flix", "&flix", "&pictures", "b4u movies", "star movies", "mh one", "maha movie",
        "classic movies", "western movies", "horror movies", "action movies", "comedy movies",
        "romance movies", "thriller movies", "sci-fi movies", "family movies", "animation movies",
        "blockbuster", "premiere", "estrenos", "peliculas", "filmes", "cinema italiano"
    ],
    
    "Series & TV Shows": [
        "series", "tv drama", "drama", "shows", "sitcom", "tv shows", "tv series", "tvland",
        "drama", "telenovela", "novelas", "soap", "episode", "season", "serial", "tv1", "tv2",
        "tv3", "tv4", "tv5", "tv6", "tv7", "tv8", "tv9", "fox life", "fox crime", "star life",
        "star world", "zee tv", "colors", "sony sab", "star plus", "star bharat", "star pravah",
        "zee anmol", "zee telugu", "zee kannada", "zee marathi", "zee bangla", "zee tamil",
        "zee punjabi", "zee one", "zee cafe", "sony set", "sony pal", "sony wah", "sony aath",
        "sony marathi", "sony ten", "sony six", "mtv", "vh1", "comedy central", "axn",
        "tnt series", "fox series", "amc series", "bbc first", "bbc brit", "bbc lifestyle",
        "bbc earth", "bbc entertainment", "itv", "channel 4", "channel 5", "sky atlantic",
        "sky witness", "sky max", "sky one", "sky showcase", "tv2", "tv3", "tv4", "tv5", "tv6",
        "tv7", "tv8", "tv9", "tv10", "tv11", "tv12", "tv13", "tv14", "tv15", "tv16", "tv17",
        "tv18", "tv19", "tv20", "k-drama", "kdrama", "korean drama", "japanese drama",
        "chinese drama", "turkish drama", "dizi", "telenovela", "novela", "soap opera",
        "reality show", "game show", "talk show", "variety show", "competition"
    ],
    
    "Sports": [
        "sport", "sports", "football", "soccer", "nba", "nfl", "cricket", "ipl", "ufc",
        "motorsport", "motor sports", "f1", "formula", "wwe", "dazn", "sky sports", "bein",
        "espn", "crichd", "pixelsports", "arena sport", "sport klub", "sport tv", "sport1",
        "sport2", "sport3", "sport4", "sport5", "sport6", "sport7", "sport8", "sport9",
        "sport10", "eurosport", "euro sport", "fox sports", "tennis", "golf", "baseball",
        "hockey", "basketball", "rugby", "racing", "nascar", "motogp", "superbike", "boxing",
        "mma", "wrestling", "fighting", "combat", "extreme sports", "outdoor sports", "fishing",
        "hunting", "horse racing", "cricket", "tennis channel", "golf channel", "nfl network",
        "nba tv", "nhl network", "mlb network", "bein sports", "sky sports", "bt sport",
        "tnt sports", "premier sports", "sportsnet", "tsn", "fox soccer", "football club",
        "real madrid tv", "barca tv", "liverpool tv", "mufc", "arsenal", "chelsea", "bayern",
        "dortmund", "juventus", "ac milan", "inter milan", "psg", "olympics", "world cup",
        "champions league", "uefa", "liga", "serie a", "premier league", "bundesliga", "laliga",
        "ligue 1", "eredivisie", "primeira liga", "super lig", "rpl", "sporting", "sport tv",
        "sport kladionica", "betting", "poker", "esports", "gaming"
    ],
    
    "News": [
        "news", "noticias", "cnn", "bbc", "al jazeera", "aljazeera", "breaking", "global news",
        "local news", "national news", "新闻", "英语新闻", "nbc news", "abc news", "cbs news",
        "fox news", "sky news", "euronews", "france 24", "dw news", "rt news", "cgtn",
        "al arabiya", "alarabiya", "al hadath", "alhurra", "al jazeera", "press tv", "irib",
        "ntv", "rtv", "tvp", "tv2", "tv3", "tv4", "tv5", "tv6", "tv7", "tv8", "tv9", "tv10",
        "news24", "news18", "aaj tak", "india tv", "ndtv", "times now", "republic tv",
        "ze news", "abp news", "news nation", "newsx", "cnbc", "bloomberg", "financial news",
        "business news", "economy", "weather news", "parliament", "congress", "senate",
        "politics", "current affairs", "analysis", "debate", "interview", "talk show",
        "morning show", "evening news", "headlines", "breaking news", "world news", "asia news",
        "europe news", "america news", "africa news", "middle east news", "local news",
        "regional news", "city news", "state news", "country news", "international news"
    ],
    
    "Kids": [
        "kids", "kid", "cartoon", "animation", "anime", "disney", "nick", "cn", "pogo",
        "family kids", "少儿", "baby", "children", "toddler", "preschool", "learning kids",
        "educational kids", "fun kids", "kids movies", "kids shows", "cartoon network",
        "nickelodeon", "nick jr", "nicktoons", "disney channel", "disney junior", "disney xd",
        "disney plus", "pbs kids", "baby tv", "baby first", "baby shark", "cbeebies", "cbeeies",
        "cbbc", "boomerang", "cartoonito", "gulli", "tiji", "piwi", "mini mini", "minimax",
        "minika", "trt cocuk", "zarok", "kidsco", "ketchup", "pop", "tiny pop", "kidoodle",
        "moonbug", "lego", "playmobil", "peppa pig", "paw patrol", "spongebob", "tom and jerry",
        "looney tunes", "mickey mouse", "dora", "diego", "blaze", "paw patrol", "peppa",
        "barney", "sesame street", "muppets", "scooby doo", "pokemon", "yugioh", "digimon",
        "dragon ball", "naruto", "one piece", "attack on titan", "demon slayer", "my hero academia",
        "anime", "manga", "cartoon network", "nickelodeon", "disney channel", "pbs kids",
        "cartoonito", "boomerang", "gulli", "tiji", "mini mini", "minimax", "minika",
        "kids zone", "kids world", "kids fun", "kids entertainment"
    ],
    
    "Music": [
        "music", "mtv", "vh1", "radio music", "музык", "音乐", "radio/music", "stingray",
        "deluxe music", "trace", "mcm", "m6 music", "mezzo", "classica", "opera", "classical",
        "jazz", "rock", "pop", "hip hop", "rap", "rnb", "country", "folk", "traditional",
        "world music", "k-pop", "kpop", "j-pop", "jpop", "c-pop", "cpom", "indie", "alternative",
        "metal", "electronic", "dance", "edm", "house", "techno", "trance", "chill", "relax",
        "meditation", "zen", "music videos", "concerts", "live music", "music channel",
        "music tv", "music station", "music box", "music world", "music videos", "music hits",
        "music classics", "music retro", "music 80s", "music 90s", "music 2000s", "music today",
        "music chart", "music countdown", "music awards", "music festival", "music performance",
        "karaoke", "music instruments", "music production", "music education"
    ],
    
    "Documentary": [
        "documentary", "documentaries", "doc", "history", "discovery", "nat geo",
        "science doc", "познав", "nature doc", "knowledge", "educational doc", "biography",
        "true story", "real story", "investigation", "crime doc", "history channel",
        "discovery channel", "national geographic", "nat geo wild", "animal planet",
        "science channel", "history hit", "documentary channel", "docubox", "docu",
        "viasat history", "viasat nature", "viasat explore", "love nature", "nature",
        "wildlife", "animals", "ocean", "space", "universe", "science", "technology",
        "engineering", "architecture", "art", "culture", "travel doc", "adventure doc",
        "expedition", "exploration", "discovery", "learning", "educational", "informative",
        "insight", "knowledge", "curiosity", "history", "ancient", "medieval", "modern",
        "ww1", "ww2", "war", "military", "aviation", "automotive", "cars", "motorcycles",
        "engineering", "construction", "megastructures", "science fiction", "space",
        "astronomy", "physics", "chemistry", "biology", "medicine", "health", "wellness",
        "psychology", "sociology", "anthropology", "archaeology", "paleontology",
        "geology", "geography", "climate", "environment", "ecology", "conservation",
        "sustainability", "renewable energy", "green", "eco", "nature doc", "wildlife doc"
    ],
    
    "Entertainment": [
        "entertainment", "general", "reality", "show", "variety", "talk show",
        "pop culture", "infotainment", "interactive", "lifestyle", "celebrity",
        "gossip", "hollywood", "bollywood", "tollywood", "kollywood", "mollywood",
        "entertainment tonight", "e!", "access hollywood", "tmz", "people", "us weekly",
        "variety", "hollywood reporter", "deadline", "screen", "empire", "total film",
        "entertainment weekly", "rolling stone", "billboard", "grammy", "oscar", "emmy",
        "golden globe", "bafta", "film awards", "music awards", "tv awards", "red carpet",
        "premiere", "after party", "celebrity news", "celebrity gossip", "celebrity life",
        "celebrity style", "celebrity fashion", "celebrity beauty", "celebrity health",
        "celebrity fitness", "celebrity relationships", "celebrity weddings", "celebrity babies",
        "celebrity homes", "celebrity cars", "celebrity vacations", "celebrity travel",
        "celebrity scandals", "celebrity controversies", "celebrity feuds", "celebrity interviews",
        "celebrity profiles", "celebrity biographies", "celebrity documentaries", "celebrity reality"
    ],
    
    "Lifestyle": [
        "lifestyle", "life style", "food", "cooking", "shop", "shopping", "relax",
        "health", "fitness", "good eats", "home", "garden", "diy", "crafts", "fashion",
        "beauty", "style", "wellness", "nutrition", "fitness", "exercise", "yoga",
        "meditation", "mindfulness", "spirituality", "travel", "leisure", "hobbies",
        "sports lifestyle", "outdoor lifestyle", "urban lifestyle", "rural lifestyle",
        "luxury lifestyle", "minimalist lifestyle", "sustainable lifestyle", "eco lifestyle",
        "green living", "healthy living", "active lifestyle", "family lifestyle",
        "parenting", "relationships", "dating", "marriage", "home decor", "interior design",
        "architecture", "renovation", "real estate", "property", "gardening", "landscaping",
        "farming", "homesteading", "cooking", "baking", "culinary", "gastronomy", "wine",
        "beer", "coffee", "tea", "food network", "cooking channel", "tastemade", "food52",
        "america test kitchen", "bon appetit", "epicurious", "serious eats", "eater",
        "food & wine", "saveur", "gourmet", "delicious", "food", "cooking", "kitchen",
        "chef", "recipe", "restaurant", "foodie", "food travel", "food culture"
    ],
    
    "Education": [
        "education", "learning", "study", "academic", "knowledge", "university",
        "college", "school", "teacher", "student", "course", "lecture", "tutorial",
        "lesson", "class", "training", "workshop", "seminar", "conference", "symposium",
        "educational tv", "learning channel", "knowledge channel", "discovery education",
        "national geographic education", "bbc learning", "coursera", "edx", "khan academy",
        "ted", "tedx", "ted talk", "lecture", "keynote", "presentation", "panel",
        "discussion", "debate", "interview", "conversation", "dialogue", "forum",
        "educational documentary", "educational series", "educational program",
        "educational content", "educational resources", "educational tools", "educational apps",
        "educational games", "educational toys", "educational software", "educational technology",
        "e-learning", "distance learning", "online learning", "virtual learning", "blended learning",
        "flipped classroom", "stem", "steam", "science education", "math education",
        "language education", "history education", "art education", "music education",
        "physical education", "health education", "environmental education"
    ],
    
    "Religion": [
        "religious", "islam", "christian", "church", "quran", "faith", "spiritual",
        "gospel", "bible", "prayer", "worship", "mosque", "temple", "synagogue",
        "cathedral", "basilica", "shrine", "holy", "sacred", "divine", "god", "allah",
        "jesus", "muhammad", "buddha", "krishna", "hindu", "buddhist", "jewish",
        "catholic", "protestant", "orthodox", "evangelical", "pentecostal", "baptist",
        "methodist", "presbyterian", "lutheran", "anglican", "episcopal", "mormon",
        "sikh", "jain", "shinto", "taoist", "confucian", "zoroastrian", "bahai",
        "faith channel", "inspirational", "motivational", "spiritual growth", "meditation",
        "yoga", "mindfulness", "consciousness", "awakening", "enlightenment", "wisdom",
        "teachings", "scriptures", "holy books", "religious texts", "spiritual texts",
        "philosophy", "ethics", "morality", "values", "virtues", "character", "integrity",
        "compassion", "love", "peace", "harmony", "balance", "inner peace", "inner strength",
        "inner wisdom", "inner journey", "spiritual journey", "spiritual path", "spiritual practice"
    ],
    
    "Science & Nature": [
        "science", "nature", "wildlife", "environment", "space", "astronomy",
        "biology", "chemistry", "physics", "geology", "oceanography", "meteorology",
        "climate", "weather", "ecology", "conservation", "sustainability", "renewable",
        "green", "eco", "planet", "earth", "universe", "cosmos", "galaxy", "star",
        "planet", "moon", "sun", "solar system", "milky way", "black hole", "nebula",
        "supernova", "constellation", "astronaut", "space exploration", "space travel",
        "rocket", "satellite", "telescope", "observatory", "science lab", "research",
        "experiment", "discovery", "innovation", "technology", "engineering", "robotics",
        "artificial intelligence", "biotechnology", "nanotechnology", "genetics", "dna",
        "evolution", "dinosaurs", "fossils", "ancient", "prehistoric", "wildlife",
        "animals", "plants", "forests", "oceans", "mountains", "deserts", "rainforest",
        "savanna", "tundra", "polar regions", "national parks", "wildlife sanctuary",
        "endangered species", "conservation", "nature documentary", "science documentary",
        "nature channel", "science channel", "discovery science", "nat geo wild",
        "animal planet", "love nature", "nature vision", "wild earth", "planet earth",
        "blue planet", "life", "our planet", "frozen planet", "green planet"
    ],
    
    "Travel & Outdoor": [
        "travel", "tourism", "outdoor", "adventure", "explore", "vacation",
        "holiday", "destination", "resort", "hotel", "beach", "mountain", "city",
        "country", "culture", "heritage", "landmark", "attraction", "expedition",
        "safari", "trekking", "hiking", "camping", "backpacking", "road trip",
        "cruise", "flight", "train", "travel guide", "travel tips", "travel vlog",
        "travel documentary", "travel show", "travel channel", "travelxp", "tastemade travel",
        "outdoor channel", "adventure tv", "expedition", "exploration", "discovery travel",
        "national geographic travel", "bbc travel", "lonely planet", "rough guides",
        "fodor's", "frommer's", "tripadvisor", "airbnb", "booking", "expedia", "kayak",
        "skyscanner", "travelocity", "orbitz", "priceline", "hotwire", "vrbo", "homeaway"
    ],
    
    "Weather": [
        "weather", "forecast", "climate", "meteorology", "temperature", "rain",
        "snow", "storm", "hurricane", "tornado", "typhoon", "cyclone", "monsoon",
        "weather channel", "weather network", "weather news", "weather report",
        "weather update", "weather alert", "weather warning", "weather advisory",
        "weather radar", "satellite", "weather map", "weather forecast", "weather prediction",
        "climate change", "global warming", "environmental weather", "extreme weather",
        "weather events", "natural disasters", "weather science", "weather education",
        "weather documentary", "weather history", "weather records", "weather statistics",
        "weather data", "weather analysis", "weather commentary", "weather expert"
    ],
    
    "Radio": [
        "radio", "fm", "am", "broadcast", "广播", "radio station", "music radio",
        "talk radio", "sports radio", "news radio", "radio show", "radio program",
        "radio host", "radio personality", "radio interview", "radio discussion",
        "radio debate", "radio call-in", "radio request", "radio music", "radio hits",
        "radio classics", "radio retro", "radio contemporary", "radio alternative",
        "radio indie", "radio rock", "radio pop", "radio hip hop", "radio rap",
        "radio rnb", "radio soul", "radio jazz", "radio blues", "radio country",
        "radio folk", "radio world", "radio international", "radio local", "radio community",
        "radio college", "radio university", "radio public", "radio commercial",
        "radio digital", "radio online", "radio streaming", "radio podcast"
    ],
    
    "Business & Finance": [
        "business", "finance", "economy", "market", "stock", "trading", "investing",
        "banking", "corporate", "industry", "commerce", "trade", "economics",
        "wealth", "money", "capital", "investment", "portfolio", "fund", "hedge",
        "equity", "bond", "commodity", "currency", "forex", "crypto", "bitcoin",
        "blockchain", "fintech", "startup", "entrepreneur", "innovation", "technology",
        "bloomberg", "cnbc", "fox business", "business news", "financial news",
        "economic news", "market news", "stock news", "trading news", "investment news",
        "business channel", "finance channel", "economy channel", "market channel",
        "stock channel", "trading channel", "investment channel", "wealth channel",
        "money channel", "capital channel", "business analysis", "financial analysis",
        "economic analysis", "market analysis", "stock analysis", "trading analysis"
    ],
    
    "Classic TV": [
        "classic", "retro", "old tv", "classic tv", "vintage", "nostalgia",
        "golden age", "silver age", "black and white", "oldies", "classic shows",
        "classic series", "classic sitcom", "classic drama", "classic comedy",
        "classic western", "classic crime", "classic mystery", "classic sci-fi",
        "classic horror", "classic romance", "classic musical", "classic variety",
        "classic game show", "classic talk show", "classic news", "classic sports",
        "classic documentary", "classic movies", "classic cinema", "classic films",
        "classic cartoons", "classic animation", "classic anime", "classic kids",
        "me tv", "antenna tv", "get tv", "grit", "laff", "buzzr", "decades",
        "retro tv", "tv land", "insp", "family tv", "cowboy channel", "western channel",
        "classic arts", "classic music", "classic radio", "classic tv network"
    ],
    
    "Comedy": [
        "comedy", "funny", "standup", "humor", "laugh", "comic", "joke", "sketch",
        "improv", "satire", "parody", "spoof", "roast", "comedy central", "comedy tv",
        "comedy channel", "comedy network", "comedy series", "comedy show", "comedy special",
        "stand-up comedy", "standup comedy", "comedy club", "comedy festival", "comedy gala",
        "comedy awards", "comedy movies", "comedy films", "comedy classics", "comedy retro",
        "comedy legends", "comedy icons", "comedy stars", "comedy personalities", "comedy hosts",
        "late night comedy", "sketch comedy", "improv comedy", "alternative comedy",
        "dark comedy", "romantic comedy", "sitcom", "situational comedy", "comedic drama",
        "comedic documentary", "comedic news", "comedic sports", "comedic talk show"
    ],
    
    "Horror & Mystery": [
        "horror", "mystery", "thriller", "true crime", "crime", "suspense",
        "psychological", "supernatural", "paranormal", "ghost", "haunted", "monster",
        "vampire", "zombie", "werewolf", "witch", "demon", "evil", "terror", "fear",
        "scary", "creepy", "dark", "gothic", "murder", "killer", "serial killer",
        "investigation", "detective", "csi", "forensic", "cold case", "unsolved",
        "mysterious", "enigma", "puzzle", "crime scene", "crime drama", "crime series",
        "true crime series", "true crime documentary", "murder mystery", "detective series",
        "investigation discovery", "crime investigation", "forensic files", "cold case files",
        "unsolved mysteries", "real crime", "criminal minds", "law and order", "ncic",
        "fbi files", "most wanted", "crime network", "mystery channel", "horror channel",
        "thriller channel", "suspense channel", "scary movies", "horror movies",
        "thriller movies", "mystery movies", "psychological thriller", "horror classic",
        "horror retro", "mystery classic", "mystery retro", "gothic horror", "supernatural horror"
    ],
    
    "Sci-Fi & Fantasy": [
        "sci fi", "sci-fi", "fantasy", "supernatural", "science fiction",
        "space opera", "cyberpunk", "dystopian", "utopian", "alternate reality",
        "parallel universe", "time travel", "alien", "extraterrestrial", "ufo",
        "futuristic", "post-apocalyptic", "apocalyptic", "magic", "mythical", "legendary",
        "fantasy world", "fantasy realm", "fantasy kingdom", "fantasy adventure",
        "fantasy epic", "fantasy series", "fantasy movies", "fantasy films", "fantasy classics",
        "sci-fi classics", "sci-fi series", "sci-fi movies", "sci-fi films", "sci-fi channel",
        "sci-fi network", "fantasy channel", "fantasy network", "star trek", "star wars",
        "doctor who", "battlestar", "stargate", "x-files", "twilight zone", "outer limits",
        "space channel", "syfy", "syfy channel", "sci-fi channel", "fantasy channel",
        "supernatural series", "supernatural movies", "supernatural shows", "mythology",
        "mythical creatures", "dragons", "wizards", "witches", "magic", "spell", "enchantment"
    ],
    
    "Auto & Motors": [
        "auto", "cars", "motor", "garage", "vehicles", "automotive", "automobile",
        "motorcycle", "motorbike", "bike", "truck", "van", "suv", "off-road", "4x4",
        "racing", "racing car", "race car", "sports car", "supercar", "hypercar",
        "classic car", "vintage car", "antique car", "muscle car", "hot rod", "custom car",
        "modified car", "tuning", "engine", "performance", "motor sport", "motorsport",
        "motoring", "driving", "auto show", "car show", "motor show", "auto racing",
        "car racing", "motor racing", "formula 1", "f1", "indycar", "nascar", "drag racing",
        "rally", "rallycross", "endurance", "le mans", "24 hours", "motogp", "superbike",
        "motorcycle racing", "auto channel", "car channel", "motor channel", "garage channel",
        "motorvision", "automotion", "auto motor", "motor trend", "car and driver",
        "road and track", "top gear", "grand tour", "auto trader", "cars.com", "edmunds",
        "kbb", "kelley blue book", "autotrader", "carfax", "vehicle history", "car maintenance",
        "auto repair", "car restoration", "car restoration", "automotive technology", "auto tech"
    ],
    
    "Games & Esports": [
        "games", "gaming", "esports", "competition", "video games", "pc games",
        "console games", "mobile games", "online games", "multiplayer", "mmo", "rpg",
        "fps", "strategy", "puzzle", "casual", "indie", "retro games", "classic games",
        "arcade", "gaming tournament", "gaming league", "esports tournament", "esports league",
        "esports championship", "gaming channel", "gaming network", "esports channel",
        "esports network", "twitch", "youtube gaming", "mixer", "gaming stream", "live stream",
        "gaming live", "esports live", "gaming events", "esports events", "gaming news",
        "esports news", "game reviews", "game previews", "game trailers", "game walkthroughs",
        "game guides", "game tutorials", "game strategies", "game tips", "game tricks",
        "game cheats", "game mods", "game development", "game design", "game art", "game music",
        "game soundtracks", "gaming culture", "gaming community", "gaming lifestyle"
    ],
    
    "Legislative & Government": [
        "legislative", "parliament", "government", "public affairs", "politics",
        "congress", "senate", "house", "assembly", "council", "municipal", "city hall",
        "state government", "federal government", "local government", "regional government",
        "government channel", "public channel", "c-span", "cspan", "parliament tv",
        "government tv", "public tv", "political tv", "political channel", "government access",
        "public access", "legislative channel", "parliament channel", "congress channel",
        "senate channel", "house channel", "assembly channel", "council channel",
        "government meeting", "public hearing", "legislative session", "parliament session",
        "congress session", "senate session", "house session", "assembly session",
        "government debate", "political debate", "political discussion", "political interview",
        "political analysis", "political commentary", "political news", "government news",
        "public policy", "law making", "legislation", "regulations", "ordinances", "bills",
        "acts", "statutes", "constitution", "constitutional law", "administrative law",
        "public administration", "governance", "public service", "civil service"
    ],
    
    "Public Service": [
        "public", "community", "service", "public tv", "community tv", "public access",
        "community access", "public broadcasting", "community broadcasting", "public media",
        "community media", "public interest", "community interest", "public service tv",
        "community service tv", "public affairs tv", "community affairs tv", "public channel",
        "community channel", "public information", "community information", "public education",
        "community education", "public health", "community health", "public safety",
        "community safety", "public welfare", "community welfare", "public assistance",
        "community assistance", "public resources", "community resources", "public services",
        "community services", "public events", "community events", "public programs",
        "community programs", "public initiatives", "community initiatives", "public outreach",
        "community outreach", "public engagement", "community engagement", "public participation",
        "community participation", "public involvement", "community involvement"
    ],
    
    "Events": [
        "event", "events", "live event", "special event", "concert", "festival",
        "conference", "convention", "expo", "exhibition", "fair", "show", "performance",
        "competition", "tournament", "championship", "cup", "race", "match", "game",
        "ceremony", "awards", "gala", "celebration", "festival", "parade", "march",
        "rally", "demonstration", "protest", "meeting", "assembly", "gathering", "happening",
        "occasion", "function", "affair", "event tv", "event channel", "events channel",
        "live events", "event coverage", "event broadcasting", "event streaming",
        "event schedule", "event calendar", "event guide", "event information",
        "event updates", "event news", "event highlights", "event recap", "event replay",
        "event archive", "event videos", "event photos", "event galleries", "event stories"
    ],
    
    "Shopping": [
        "shop", "shopping", "store", "sales", "retail", "mall", "outlet", "boutique",
        "department store", "online shop", "e-commerce", "shopping channel", "shopping tv",
        "shopping network", "home shopping", "tv shopping", "shop at home", "buy", "purchase",
        "deal", "bargain", "discount", "sale", "clearance", "offer", "promotion", "special",
        "qvc", "hsn", "shop hq", "shop lc", "jewelry tv", "jewelry shopping", "fashion shopping",
        "beauty shopping", "home shopping", "electronics shopping", "gadget shopping",
        "gift shopping", "holiday shopping", "seasonal shopping", "clearance shopping",
        "bargain shopping", "discount shopping", "deal shopping", "offer shopping",
        "promotion shopping", "special shopping", "exclusive shopping", "limited shopping",
        "collectible shopping", "vintage shopping", "antique shopping", "art shopping",
        "craft shopping", "hobby shopping", "sports shopping", "outdoor shopping"
    ],
    
    "Food & Cooking": [
        "food", "cooking", "kitchen", "chef", "culinary", "gastronomy", "cuisine",
        "recipe", "meal", "dish", "course", "appetizer", "main course", "dessert",
        "baking", "pastry", "bread", "cake", "pastry", "grilling", "bbq", "barbecue",
        "smoking", "roasting", "frying", "sauteing", "steaming", "boiling", "poaching",
        "braising", "stewing", "sous vide", "slow cooking", "pressure cooking", "air frying",
        "microwave", "oven", "stove", "range", "cookware", "utensils", "tools", "equipment",
        "ingredients", "spices", "herbs", "seasonings", "food network", "cooking channel",
        "food channel", "cooking tv", "food tv", "cooking shows", "food shows",
        "cooking competition", "food competition", "cooking reality", "food reality",
        "cooking documentary", "food documentary", "cooking travel", "food travel",
        "cooking culture", "food culture", "cooking lifestyle", "food lifestyle"
    ],
    
    "Relaxation": [
        "relax", "ambient", "chill", "zen", "meditation", "mindfulness", "peaceful",
        "calm", "serene", "tranquil", "quiet", "stillness", "silence", "nature sounds",
        "ocean waves", "rain sounds", "forest sounds", "mountain sounds", "desert sounds",
        "water sounds", "wind sounds", "bird sounds", "animal sounds", "music relax",
        "ambient music", "chill music", "zen music", "meditation music", "peaceful music",
        "calm music", "serene music", "tranquil music", "quiet music", "stillness music",
        "silence music", "nature music", "water music", "forest music", "mountain music",
        "relaxation channel", "ambient channel", "chill channel", "zen channel",
        "meditation channel", "mindfulness channel", "peaceful channel", "calm channel",
        "serene channel", "tranquil channel", "relaxation tv", "ambient tv", "chill tv",
        "zen tv", "meditation tv", "mindfulness tv", "peaceful tv", "calm tv",
        "relaxation videos", "ambient videos", "chill videos", "zen videos",
        "meditation videos", "mindfulness videos", "peaceful videos", "calm videos"
    ],
    
    # Regional Categories
    "Regional Americas": [
        "usa", "us ", "united states", "canada", "mexico", "brazil", "argentina",
        "chile", "colombia", "peru", "venezuela", "uruguay", "bolivia", "paraguay",
        "ecuador", "guyana", "suriname", "french guiana", "panama", "costa rica",
        "nicaragua", "honduras", "el salvador", "guatemala", "belize", "cuba",
        "jamaica", "haiti", "dominican republic", "puerto rico", "bahamas", "trinidad",
        "barbados", "st lucia", "st vincent", "grenada", "antigua", "dominica",
        "americas", "north america", "south america", "central america", "caribbean",
        "latin america", "hispanic america", "anglo america", "north american",
        "south american", "central american", "caribbean", "latin american", "american",
        "canadian", "mexican", "brazilian", "argentine", "chilean", "colombian",
        "peruvian", "venezuelan", "uruguayan", "bolivian", "paraguayan", "ecuadorian"
    ],
    
    "Regional Europe": [
        "uk", "united kingdom", "england", "scotland", "wales", "northern ireland",
        "ireland", "germany", "france", "italy", "spain", "portugal", "netherlands",
        "belgium", "luxembourg", "switzerland", "austria", "sweden", "norway",
        "denmark", "finland", "iceland", "poland", "czech", "slovakia", "hungary",
        "romania", "bulgaria", "greece", "cyprus", "malta", "albania", "croatia",
        "slovenia", "bosnia", "serbia", "montenegro", "macedonia", "kosovo", "estonia",
        "latvia", "lithuania", "belarus", "ukraine", "moldova", "russia", "georgia",
        "armenia", "azerbaijan", "turkey", "europe", "european", "western europe",
        "eastern europe", "northern europe", "southern europe", "central europe",
        "british", "english", "german", "french", "italian", "spanish", "portuguese",
        "dutch", "belgian", "swiss", "austrian", "swedish", "norwegian", "danish",
        "finnish", "icelandic", "polish", "czech", "slovak", "hungarian", "romanian",
        "bulgarian", "greek", "croatian", "slovenian", "serbian", "albanian", "estonian",
        "latvian", "lithuanian", "belarusian", "ukrainian", "moldovan", "georgian",
        "armenian", "azerbaijani", "turkish"
    ],
    
    "Regional Middle East": [
        "uae", "saudi", "qatar", "oman", "kuwait", "bahrain", "iraq", "iran",
        "israel", "palestine", "jordan", "lebanon", "syria", "yemen", "egypt",
        "libya", "tunisia", "algeria", "morocco", "mauritania", "sudan", "somalia",
        "djibouti", "comoros", "middle east", "middle eastern", "arab", "arabic",
        "gulf", "gulf states", "levant", "mesopotamia", "persian", "persian gulf",
        "arabian peninsula", "arabian", "emirati", "saudi", "qatari", "omani",
        "kuwaiti", "bahraini", "iraqi", "iranian", "israeli", "palestinian", "jordanian",
        "lebanese", "syrian", "yemeni", "egyptian", "libyan", "tunisian", "algerian",
        "moroccan", "mauritanian", "sudanese", "somali", "djiboutian", "comorian"
    ],
    
    "Regional Asia": [
        "india", "pakistan", "bangladesh", "china", "japan", "korea", "indonesia",
        "malaysia", "thailand", "philippines", "taiwan", "vietnam", "cambodia",
        "laos", "myanmar", "singapore", "brunei", "east timor", "nepal", "bhutan",
        "sri lanka", "maldives", "mongolia", "hong kong", "macau", "asia", "asian",
        "south asia", "southeast asia", "east asia", "central asia", "west asia",
        "indian", "pakistani", "bangladeshi", "chinese", "japanese", "korean",
        "indonesian", "malaysian", "thai", "filipino", "taiwanese", "vietnamese",
        "cambodian", "laotian", "myanmar", "singaporean", "nepali", "bhutanese",
        "sri lankan", "maldivian", "mongolian", "hong kong", "macau"
    ],
    
    "Regional Africa": [
        "africa", "nigeria", "south africa", "egypt", "morocco", "algeria",
        "tunisia", "libya", "sudan", "mauritania", "senegal", "gambia", "guinea",
        "guinea-bissau", "sierra leone", "liberia", "cote d'ivoire", "ghana",
        "togo", "benin", "burkina faso", "mali", "niger", "chad", "cameroon",
        "central african republic", "equatorial guinea", "gabon", "congo",
        "democratic republic of congo", "rwanda", "burundi", "uganda", "kenya",
        "tanzania", "mozambique", "malawi", "zambia", "zimbabwe", "botswana",
        "namibia", "angola", "eswatini", "lesotho", "madagascar", "comoros",
        "mauritius", "seychelles", "eritrea", "ethiopia", "somalia", "djibouti",
        "african", "sub-saharan africa", "north africa", "west africa", "east africa",
        "central africa", "southern africa", "nigerian", "south african", "egyptian",
        "moroccan", "algerian", "tunisian", "libyan", "sudanese", "mauritanian",
        "senegalese", "ghanaian", "kenyan", "tanzanian", "ethiopian", "somali"
    ],
    
    "Regional CIS": [
        "russia", "ukraine", "kazakhstan", "belarus", "uzbekistan", "turkmenistan",
        "kyrgyzstan", "tajikistan", "azerbaijan", "armenia", "georgia", "moldova",
        "cis", "commonwealth of independent states", "russian", "ukrainian",
        "kazakh", "belarusian", "uzbek", "turkmen", "kyrgyz", "tajik", "azerbaijani",
        "armenian", "georgian", "moldovan", "post-soviet", "soviet", "russian language",
        "russian speaking", "russian tv", "ukrainian tv", "kazakh tv", "belarus tv",
        "uzbek tv", "turkmen tv", "kyrgyz tv", "tajik tv", "azerbaijan tv",
        "armenian tv", "georgian tv", "moldova tv"
    ],
    
    "Regional Balkans": [
        "serbia", "croatia", "bosnia", "montenegro", "macedonia", "albania",
        "kosovo", "slovenia", "bulgaria", "romania", "greece", "turkey", "balkans",
        "balkan", "southeastern europe", "serbian", "croatian", "bosnian",
        "montenegrin", "macedonian", "albanian", "kosovar", "slovenian", "bulgarian",
        "romanian", "greek", "turkish", "ex-yu", "former yugoslavia", "yugoslav",
        "balkan music", "balkan culture", "balkan entertainment", "balkan tv"
    ],
    
    "Chinese Regions": [
        "beijing", "shanghai", "guangdong", "zhejiang", "jiangsu", "shandong",
        "henan", "hebei", "hunan", "anhui", "fujian", "jiangxi", "sichuan",
        "chongqing", "xinjiang", "tibet", "内蒙古", "北京", "广东", "浙江",
        "江苏", "山东", "河南", "河北", "湖南", "安徽", "福建", "江西",
        "四川", "重庆", "新疆", "西藏", "广西", "云南", "贵州", "陕西",
        "甘肃", "青海", "宁夏", "辽宁", "吉林", "黑龙江", "山西", "湖北",
        "海南", "台湾", "香港", "澳门", "chinese", "china", "mandarin",
        "cantonese", "hokkien", "teochew", "hakka", "chinese tv", "china tv",
        "mainland china", "china mainland", "chinese language", "chinese speaking",
        "chinese entertainment", "chinese drama", "chinese movies", "chinese music",
        "chinese news", "chinese documentary", "chinese lifestyle", "chinese culture"
    ],
    
    "Pluto/Plex/OTT": [
        "pluto", "plex", "roku", "tubi", "xumo", "distrotv", "yupptv", "lg tv",
        "samsung tv", "vizio", "amazon fire", "apple tv", "android tv", "chromecast",
        "free tv", "free streaming", "free channels", "free movies", "free tv shows",
        "free entertainment", "free lifestyle", "free documentary", "free sports",
        "free news", "free kids", "free music", "free series", "free reality",
        "free food", "free travel", "free nature", "free science", "free history",
        "free classic", "free retro", "free comedy", "free horror", "free sci-fi",
        "pluto tv", "plex tv", "roku tv", "tubi tv", "xumo tv", "distro tv",
        "yupptv", "lg channels", "samsung tv plus", "vizio watchfree", "amazon freevee",
        "freevee", "imdb tv", "popcornflix", "filmrise", "shout factory", "crackle",
        "redbox", "peacock", "paramount plus", "discovery plus", "hulu", "netflix",
        "amazon prime", "apple tv plus", "disney plus", "hbomax", "max", "hbo max"
    ],
    
    "YouTube & Online": [
        "youtube", "online", "web tv", "internet tv", "streaming", "live stream",
        "online stream", "web stream", "digital stream", "youtube channel", "youtube tv",
        "youtube live", "youtube music", "youtube gaming", "youtube news", "youtube sports",
        "youtube entertainment", "youtube lifestyle", "youtube documentary", "youtube education",
        "youtube kids", "youtube series", "youtube movies", "youtube shorts", "youtube videos",
        "online channel", "online tv", "online streaming", "online content", "web series",
        "web movies", "web shows", "digital series", "digital movies", "digital shows",
        "internet series", "internet movies", "internet shows", "streaming service",
        "streaming platform", "streaming network", "streaming channel", "streaming content"
    ],
    
    "4K & UHD": [
        "4k", "8k", "uhd", "ultra hd", "high definition", "hdr", "dolby vision",
        "4k ultra", "4k hd", "uhd 4k", "ultra high definition", "ultra hd 4k",
        "4k resolution", "4k quality", "4k video", "4k content", "4k channel",
        "4k movies", "4k series", "4k sports", "4k documentary", "4k nature",
        "4k travel", "4k music", "4k entertainment", "uhd movies", "uhd series",
        "uhd sports", "uhd documentary", "uhd nature", "uhd travel", "uhd music",
        "uhd entertainment", "4k tv", "uhd tv", "4k hdr", "uhd hdr", "dolby vision",
        "high dynamic range", "wide color gamut", "high frame rate", "hfr"
    ],
    
    "24/7 Channels": [
        "24 7", "24/7", "twenty four seven", "24 hours", "all day", "always on",
        "continuous", "non-stop", "round the clock", "around the clock",
        "24/7 streaming", "24/7 live", "24/7 channel", "24/7 content", "24/7 entertainment",
        "24/7 movies", "24/7 series", "24/7 sports", "24/7 news", "24/7 music",
        "24/7 kids", "24/7 documentary", "24/7 lifestyle", "24/7 travel", "24/7 nature",
        "24/7 comedy", "24/7 horror", "24/7 sci-fi", "24/7 classic", "24/7 retro",
        "24/7 anime", "24/7 cartoon", "24/7 gaming", "24/7 food", "24/7 cooking"
    ],
    
    "Adult": [
        "xxx", "adult", "porn", "sex", "erotic", "erotica", "nude", "nudity",
        "18+", "adults only", "mature", "explicit", "hardcore", "softcore",
        "adult content", "adult movies", "adult series", "adult entertainment",
        "adult channel", "adult network", "adult tv", "adult streaming",
        "erotic movies", "erotic series", "erotic entertainment", "erotic channel",
        "erotic network", "erotic tv", "porn movies", "porn series", "porn entertainment",
        "porn channel", "porn network", "porn tv", "xxx movies", "xxx series",
        "xxx entertainment", "xxx channel", "xxx network", "xxx tv", "playboy",
        "penthouse", "hustler", "brazzers", "bangbros", "mofos", "naughty america",
        "vivid", "wicked", "digital playground", "evil angel", "girlfriends films",
        "adult time", "adult swim", "sex tv", "hot tv", "erotic films", "erotic videos",
        "adult videos", "mature content", "adult programming", "adult entertainment network"
    ],
    
    # Fallback for unassigned
    "Other": []
}

SUPPORTED_INLINE_DIRECTIVES = (
    '#EXTVLCOPT:',
    '#KODIPROP:',
    '#EXT-X-APP',
    '#EXT-X-APTV-TYPE',
    '#EXT-X-SUB-URL',
)


def parse_quoted_attributes(line):
    return {
        match.group(1): match.group(2)
        for match in re.finditer(r'([\w-]+)="([^"]*)"', line)
    }


def build_header_map(directives):
    headers = {}
    for directive in directives:
        if not directive.startswith('#EXTVLCOPT:'):
            continue
        option = directive[len('#EXTVLCOPT:'):].strip()
        if '=' not in option:
            continue
        key, value = option.split('=', 1)
        key = key.strip().lower()
        value = value.strip()
        if not value:
            continue
        if key in ('http-referrer', 'http-referer'):
            headers['Referer'] = value
        elif key == 'http-user-agent':
            headers['User-Agent'] = value
        elif key == 'http-origin':
            headers['Origin'] = value
        elif key == 'http-cookie':
            headers['Cookie'] = value
    return headers


def assign_category(title: str, group: str, tvg_name: str = "") -> str:
    """Automatically assign a category based on title, group, and tvg-name."""
    text = f"{title} {group} {tvg_name}".lower()

    # Check categories in order of specificity (longer/more specific first)
    best_category = "Other"
    max_matches = 0

    for category, keywords in CATEGORY_KEYWORDS.items():
        if not keywords:  # Skip "Other"
            continue

        matches = sum(1 for kw in keywords if kw.lower() in text)

        if matches > max_matches:
            max_matches = matches
            best_category = category

    # If no good match found, fall back to original group (cleaned)
    if best_category == "Other":
        clean_group = group.strip()
        if clean_group and clean_group != "Other":
            return clean_group
        return "Other"

    return best_category


def parse_m3u(content):
    """Parses M3U/M3U8 content and returns a list of dictionaries with stream info."""
    streams = []
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('#EXTINF:'):
            attrs = parse_quoted_attributes(line)
            metadata = line[8:]
            title = metadata.split(',')[-1].strip() if ',' in metadata else "Unknown"

            group = attrs.get('group-title', 'Other')
            logo = attrs.get('tvg-logo', '')
            tvg_id = attrs.get('tvg-id', '')
            tvg_name = attrs.get('tvg-name', '')
            tvg_chno = attrs.get('tvg-chno', '')

            directives = []
            i += 1
            while i < len(lines) and lines[i].strip().startswith('#'):
                tag_line = lines[i].strip()
                if tag_line.startswith(SUPPORTED_INLINE_DIRECTIVES):
                    directives.append(tag_line)
                i += 1

            # Skip empty lines
            while i < len(lines) and not lines[i].strip():
                i += 1

            if i < len(lines):
                url = lines[i].strip()
                if url.startswith('http'):
                    streams.append({
                        'title': title,
                        'url': url,
                        'group': group,
                        'logo': logo,
                        'tvg_id': tvg_id,
                        'tvg_name': tvg_name,
                        'tvg_chno': tvg_chno,
                        'directives': directives,
                        'headers': build_header_map(directives),
                    })
        i += 1
    return streams


def fetch_playlist(source):
    """Fetches a single playlist URL and returns the parsed streams."""
    print(f"Fetching: {source['name']} ({source['url']})")
    try:
        response = requests.get(source['url'], timeout=15)
        if response.status_code == 200:
            return parse_m3u(response.text)
    except Exception as e:
        print(f"Error fetching {source['name']}: {e}")
    return []


def check_url(stream, session):
    """Perform a HEAD/GET request to check if the URL is reachable."""
    headers = session.headers.copy()
    headers.update(stream.get('headers', {}))

    try:
        response = session.head(stream['url'], timeout=5, allow_redirects=True, headers=headers)
        if 200 <= response.status_code < 400:
            return stream

        response = session.get(stream['url'], timeout=3, stream=True, headers=headers)
        if 200 <= response.status_code < 400:
            return stream
    except:
        pass
    return None


def main():
    if not os.path.exists(PLAYLISTS_JSON):
        print(f"Error: {PLAYLISTS_JSON} not found.")
        return

    with open(PLAYLISTS_JSON, 'r', encoding='utf-8') as f:
        sources = json.load(f)

    # Ignore the official combined source
    fetch_sources = [s for s in sources if s.get('id') != 'joy-tv-combined']

    print(f"Phase 0: {len(sources) - len(fetch_sources)} source(s) ignored (Joy TV Combined).")
    all_streams = []

    print(f"Phase 1: Fetching {len(fetch_sources)} playlists...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        future_to_source = {executor.submit(fetch_playlist, s): s for s in fetch_sources}
        for future in as_completed(future_to_source):
            all_streams.extend(future.result())

    print(f"Total entries found: {len(all_streams)}")

    print("Phase 2: Deduplicating...")
    unique_streams = {}
    for s in all_streams:
        url = s['url']
        if url not in unique_streams:
            unique_streams[url] = s
        else:
            # Merge better metadata
            existing = unique_streams[url]
            if not existing['logo'] and s['logo']:
                existing['logo'] = s['logo']
            if existing['group'] == 'Other' and s['group'] != 'Other':
                existing['group'] = s['group']
            for field in ('tvg_id', 'tvg_name', 'tvg_chno'):
                if not existing.get(field) and s.get(field):
                    existing[field] = s[field]

            existing_directives = existing.setdefault('directives', [])
            for d in s.get('directives', []):
                if d not in existing_directives:
                    existing_directives.append(d)
            existing['headers'] = build_header_map(existing_directives)

    candidate_streams = list(unique_streams.values())
    print(f"Unique entries to verify: {len(candidate_streams)}")

    # === NEW: Auto-assign categories ===
    print("Phase 2.5: Auto-assigning categories...")
    for stream in candidate_streams:
        stream['group'] = assign_category(
            stream['title'],
            stream.get('group', 'Other'),
            stream.get('tvg_name', '')
        )

    print("Phase 3: Verifying links (this may take a while)...")
    verified_streams = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    })

    with ThreadPoolExecutor(max_workers=100) as executor:
        future_to_stream = {executor.submit(check_url, s, session): s for s in candidate_streams}

        count = 0
        for future in as_completed(future_to_stream):
            result = future.result()
            if result:
                verified_streams.append(result)

            count += 1
            if count % 1000 == 0:
                print(f"Progress: {count}/{len(candidate_streams)} checked, "
                      f"{len(verified_streams)} working...")

    print(f"Verification complete. Working entries: {len(verified_streams)}")

    verified_streams.sort(key=lambda x: (x['group'].lower(), x['title'].lower()))

    print(f"Phase 4: Saving to {OUTPUT_M3U8}...")
    with open(OUTPUT_M3U8, 'w', encoding='utf-8') as f:
        f.write("#EXTM3U\n")
        for s in verified_streams:
            logo_part = f' tvg-logo="{s["logo"]}"' if s["logo"] else ""
            group_part = f' group-title="{s["group"]}"' if s["group"] else ""
            id_part = f' tvg-id="{s["tvg_id"]}"' if s["tvg_id"] else ""
            name_part = f' tvg-name="{s["tvg_name"]}"' if s.get("tvg_name") else ""
            chno_part = f' tvg-chno="{s["tvg_chno"]}"' if s.get("tvg_chno") else ""

            f.write(f'#EXTINF:-1{id_part}{name_part}{logo_part}{chno_part}{group_part},{s["title"]}\n')
            for directive in s.get('directives', []):
                f.write(f'{directive}\n')
            f.write(f'{s["url"]}\n')

    print("Success! All steps completed.")


if __name__ == "__main__":
    main()