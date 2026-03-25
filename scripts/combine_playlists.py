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