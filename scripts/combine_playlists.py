import json
import requests
import re
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

# Determine paths relative to this script's location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# If running from scripts/ folder, assets is in the parent directory
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
PLAYLISTS_JSON = os.path.join(PROJECT_ROOT, 'assets', 'playlists.json')
OUTPUT_M3U8 = os.path.join(PROJECT_ROOT, 'assets', 'default_playlist.m3u8')

def parse_m3u(content):
    """
    Parses M3U/M3U8 content and returns a list of dictionaries with stream info.
    """
    streams = []
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('#EXTINF:'):
            # Extract metadata from #EXTINF line
            metadata = line[8:]
            
            group_match = re.search(r'group-title="([^"]+)"', metadata)
            logo_match = re.search(r'tvg-logo="([^"]+)"', metadata)
            id_match = re.search(r'tvg-id="([^"]+)"', metadata)
            
            title = metadata.split(',')[-1].strip()
            
            group = group_match.group(1) if group_match else "Other"
            logo = logo_match.group(1) if logo_match else ""
            tvg_id = id_match.group(1) if id_match else ""
            
            i += 1
            while i < len(lines) and (not lines[i].strip() or lines[i].startswith('#')):
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
                        'raw_extinf': line
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
    """Perform a HEAD request to check if the URL is reachable."""
    try:
        response = session.head(stream['url'], timeout=5, allow_redirects=True)
        if response.status_code >= 200 and response.status_code < 400:
            return stream
        
        response = session.get(stream['url'], timeout=3, stream=True)
        if response.status_code >= 200 and response.status_code < 400:
            return stream
    except:
        pass
    return None

def main():
    if not os.path.exists(PLAYLISTS_JSON):
        print(f"Error: {PLAYLISTS_JSON} not found.")
        return
    
    p_json = PLAYLISTS_JSON
    o_m3u8 = OUTPUT_M3U8

    with open(p_json, 'r') as f:
        sources = json.load(f)

    # Ignore the official combined source (recursion protection)
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
            if not unique_streams[url]['logo'] and s['logo']:
                unique_streams[url]['logo'] = s['logo']
            if unique_streams[url]['group'] == 'Other' and s['group'] != 'Other':
                unique_streams[url]['group'] = s['group']

    candidate_streams = list(unique_streams.values())
    print(f"Unique entries to verify: {len(candidate_streams)}")

    print("Phase 3: Verifying links (this may take a while)...")
    verified_streams = []
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
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
                print(f"Progress: {count}/{len(candidate_streams)} checked, {len(verified_streams)} working...")

    print(f"Verification complete. Working entries: {len(verified_streams)}")

    verified_streams.sort(key=lambda x: (x['group'].lower(), x['title'].lower()))

    print(f"Phase 4: Saving to {o_m3u8}...")
    with open(o_m3u8, 'w', encoding='utf-8') as f:
        f.write("#EXTM3U\n")
        for s in verified_streams:
            logo_part = f' tvg-logo="{s["logo"]}"' if s["logo"] else ""
            group_part = f' group-title="{s["group"]}"' if s["group"] else ""
            id_part = f' tvg-id="{s["tvg_id"]}"' if s["tvg_id"] else ""
            
            f.write(f'#EXTINF:-1{id_part}{logo_part}{group_part},{s["title"]}\n')
            f.write(f'{s["url"]}\n')

    print("Success! All steps completed.")

if __name__ == "__main__":
    main()
