#!/bin/bash

# Setup colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Joy TV Playlist Generator...${NC}"

# Navigate to script directory if needed
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Error: python3 could not be found. Please install it first."
    exit 1
fi

# Set up virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Install dependencies
echo -e "${YELLOW}Ensuring dependencies are installed...${NC}"
pip install -q requests

# Run the generator
echo -e "${GREEN}Generating combined playlist (this may take 5-10 minutes for verification)...${NC}"
python3 "$SCRIPT_DIR/combine_playlists.py"

echo -e "${BLUE}Playlist generation complete!${NC}"
echo -e "You can now push ${YELLOW}assets/default_playlist.m3u8${NC} and ${YELLOW}assets/playlists.json${NC} to your repo."
