import os
import re

# Determine paths relative to this script's location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
M3U8_PATH = os.path.join(PROJECT_ROOT, 'assets', 'default_playlist.m3u8')

OUTPUT_PATH = os.path.join(PROJECT_ROOT, 'assets', 'categories.txt')

def parse_quoted_attributes(line):
    return {
        match.group(1): match.group(2)
        for match in re.finditer(r'([\w-]+)="([^"]*)"', line)
    }

def list_categories():
    if not os.path.exists(M3U8_PATH):
        print(f"Error: {M3U8_PATH} not found.")
        return

    categories = set()
    
    try:
        with open(M3U8_PATH, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if line.startswith('#EXTINF:'):
                    attrs = parse_quoted_attributes(line)
                    group = attrs.get('group-title', 'Other')
                    categories.add(group)
    except Exception as e:
        print(f"Error reading playlist: {e}")
        return

    sorted_categories = sorted(list(categories))
    
    try:
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            f.write(f"Found {len(sorted_categories)} unique categories:\n\n")
            for idx, category in enumerate(sorted_categories, 1):
                f.write(f"{idx}. {category}\n")
        print(f"Successfully saved {len(sorted_categories)} categories to {OUTPUT_PATH}")
    except Exception as e:
        print(f"Error saving to {OUTPUT_PATH}: {e}")

if __name__ == "__main__":
    list_categories()
