import os
import re
from collections import defaultdict

# Determine paths relative to this script's location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
M3U8_PATH = os.path.join(PROJECT_ROOT, 'assets', 'default_playlist.m3u8')
OUTPUT_PATH = os.path.join(PROJECT_ROOT, 'assets', 'channels.txt')

# ====================== CATEGORY KEYWORDS ======================
CATEGORY_KEYWORDS = {
    "Movies": ["movie", "movies", "cinema", "film", "vod", "кинозал", "kino"],
    "Series & TV Shows": ["series", "tv drama", "drama", "shows", "sitcom", "tv shows"],
    "Sports": ["sport", "sports", "football", "soccer", "nba", "nfl", "cricket", "ipl", "ufc",
               "motorsport", "motor sports", "f1", "wwe", "dazn", "sky sports", "bein", "espn",
               "crichd", "pixelsports"],
    "News": ["news", "noticias", "cnn", "bbc", "al jazeera", "breaking", "global news",
             "local news", "national news", "新闻", "英语新闻"],
    "Kids": ["kids", "kid", "cartoon", "animation", "anime", "disney", "nick", "cn", "pogo",
             "family kids", "少儿"],
    "Music": ["music", "mtv", "vh1", "radio music", "музык", "音乐", "radio/music"],
    "Documentary": ["documentary", "documentaries", "doc", "history", "discovery", "nat geo",
                    "science doc", "познав", "nature doc"],
    "Entertainment": ["entertainment", "general", "reality", "show", "variety", "talk show",
                      "pop culture", "infotainment", "interactive"],
    "Lifestyle": ["lifestyle", "life style", "food", "cooking", "shop", "shopping", "relax",
                  "health", "fitness", "good eats"],
    "Education": ["education", "learning", "study", "academic", "knowledge"],
    "Religion": ["religious", "islam", "christian", "church", "quran", "faith"],
    "Science & Nature": ["science", "nature", "wildlife", "environment", "space"],
    "Travel & Outdoor": ["travel", "tourism", "outdoor", "adventure", "explore"],
    "Weather": ["weather", "forecast", "climate"],
    "Radio": ["radio", "fm", "am", "broadcast", "广播"],
    "Business & Finance": ["business", "finance", "economy", "market", "stock"],
    "Classic TV": ["classic", "retro", "old tv", "classic tv"],
    "Comedy": ["comedy", "funny", "standup", "humor"],
    "Horror & Mystery": ["horror", "mystery", "thriller", "true crime", "crime"],
    "Sci-Fi & Fantasy": ["sci fi", "sci-fi", "fantasy", "supernatural"],
    "Auto & Motors": ["auto", "cars", "motor", "garage", "vehicles"],
    "Games & Esports": ["games", "gaming", "esports", "competition"],
    "Legislative & Government": ["legislative", "parliament", "government", "public affairs"],
    "Public Service": ["public", "community", "service"],
    "Events": ["event", "events", "live event"],
    "Shopping": ["shop", "shopping", "store", "sales"],
    "Food & Cooking": ["food", "cooking", "kitchen", "chef"],
    "Relaxation": ["relax", "ambient", "chill", "zen"],
    "Regional Americas": ["usa", "us ", "united states", "canada", "mexico", "brazil", "argentina",
                          "chile", "colombia", "peru", "venezuela", "uruguay", "bolivia", "paraguay"],
    "Regional Europe": ["uk", "united kingdom", "germany", "france", "italy", "spain", "netherlands",
                        "sweden", "norway", "denmark", "finland", "poland", "romania", "greece",
                        "czech", "slovakia", "slovenia", "hungary", "belgium", "austria", "switzerland"],
    "Regional Middle East": ["uae", "saudi", "qatar", "oman", "kuwait", "iraq", "iran", "israel",
                             "palestine", "jordan", "lebanon", "syria", "yemen", "bahrain"],
    "Regional Asia": ["india", "pakistan", "bangladesh", "china", "japan", "korea", "indonesia",
                      "malaysia", "thailand", "philippines", "taiwan", "vietnam"],
    "Regional Africa": ["africa", "nigeria", "south africa", "egypt", "morocco", "algeria",
                        "tunisia", "cameroon", "senegal", "somalia"],
    "Regional CIS": ["russia", "ukraine", "kazakhstan", "belarus", "uzbekistan", "turkmenistan"],
    "Regional Balkans": ["serbia", "croatia", "bosnia", "montenegro", "macedonia", "albania"],
    "Chinese Regions": ["beijing", "shanghai", "guangdong", "zhejiang", "jiangsu", "shandong",
                        "henan", "hebei", "hunan", "anhui", "fujian", "jiangxi", "sichuan",
                        "chongqing", "xinjiang", "tibet", "内蒙古", "北京", "广东", "浙江",
                        "江苏", "山东", "河南", "河北"],
    "Pluto/Plex/OTT": ["pluto", "plex", "roku", "tubi", "xumo", "distrotv", "yupptv", "lg tv"],
    "YouTube & Online": ["youtube", "online", "web tv"],
    "4K & UHD": ["4k", "8k", "uhd"],
    "24/7 Channels": ["24 7", "24/7"],
    "Adult": ["xxx", "adult", "porn"],
    "Other": []
}

def parse_quoted_attributes(line):
    return {
        match.group(1): match.group(2)
        for match in re.finditer(r'([\w-]+)="([^"]*)"', line)
    }

def assign_category(title: str, group: str, tvg_name: str = "") -> str:
    """Automatically assign a category based on title, group, and tvg-name."""
    text = f"{title} {group} {tvg_name}".lower()
    best_category = "Other"
    max_matches = 0

    for category, keywords in CATEGORY_KEYWORDS.items():
        if not keywords: continue
        matches = sum(1 for kw in keywords if kw.lower() in text)
        if matches > max_matches:
            max_matches = matches
            best_category = category

    if best_category == "Other":
        clean_group = group.strip()
        if clean_group and clean_group != "Other":
            return clean_group
        return "Other"
    return best_category

def list_channels():
    if not os.path.exists(M3U8_PATH):
        print(f"Error: {M3U8_PATH} not found.")
        return

    channels_by_category = defaultdict(set)

    try:
        with open(M3U8_PATH, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if line.startswith('#EXTINF:'):
                    attrs = parse_quoted_attributes(line)
                    metadata = line[8:]
                    title = metadata.split(',')[-1].strip() if ',' in metadata else "Unknown"
                    group = attrs.get('group-title', 'Other')
                    tvg_name = attrs.get('tvg-name', '')
                    
                    assigned = assign_category(title, group, tvg_name)
                    channels_by_category[assigned].add(title)
    except Exception as e:
        print(f"Error reading playlist: {e}")
        return

    total_unique = sum(len(c) for c in channels_by_category.values())
    
    try:
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            f.write(f"Total Unique Channels: {total_unique}\n\n")
            
            # Sort categories by name
            for category in sorted(channels_by_category.keys()):
                channels = sorted(list(channels_by_category[category]))
                f.write(f"=== {category} ({len(channels)} channels) ===\n")
                for name in channels:
                    f.write(f"- {name}\n")
                f.write("\n")
                
        print(f"Successfully saved {total_unique} categorized channel names to {OUTPUT_PATH}")
    except Exception as e:
        print(f"Error saving to {OUTPUT_PATH}: {e}")

if __name__ == "__main__":
    list_channels()
