#!/bin/bash

set -e

echo "[ZoomChecker Installer] Starting setup v1..."

# ---- 1. Install Hammerspoon if not present ----
if ! [ -d "/Applications/Hammerspoon.app" ]; then
    echo "[ZoomChecker Installer] Hammerspoon not found. Installing latest version..."
    curl -L -o ~/Downloads/Hammerspoon.zip https://github.com/Hammerspoon/hammerspoon/releases/download/1.0.0/Hammerspoon-1.0.0.zip
    unzip -q ~/Downloads/Hammerspoon.zip -d ~/Downloads/
    mv -f ~/Downloads/Hammerspoon.app /Applications/
    echo "[ZoomChecker Installer] Hammerspoon installed."
else
    echo "[ZoomChecker Installer] Hammerspoon already installed."
fi

# ---- 2. Clone or update the ZoomChecker repo ----
echo "[ZoomChecker Installer] Installing ZoomChecker files..."
mkdir -p ~/.hammerspoon
cd ~/.hammerspoon

REPO_NAME="ZoomChecker"
REPO_URL="https://github.com/chris-snapops/ZoomChecker.git"

if [ -d "$REPO_NAME" ]; then
    echo "[ZoomChecker Installer] ZoomChecker already exists. Pulling latest changes..."
    cd "$REPO_NAME"
    git pull
else
    git clone "$REPO_URL"
fi

# ---- 3. Ensure init.lua includes the require line ----
INIT_FILE="$HOME/.hammerspoon/init.lua"
REQUIRE_LINE='require("ZoomChecker.checkZoomMeeting")'

if ! grep -Fxq "$REQUIRE_LINE" "$INIT_FILE" 2>/dev/null; then
    echo "$REQUIRE_LINE" >> "$INIT_FILE"
    echo "[ZoomChecker Installer] Added require line to init.lua."
else
    echo "[ZoomChecker Installer] Require line already present in init.lua."
fi

# ---- 4. Add Hammerspoon to login items ----
osascript <<EOF
tell application "System Events"
    if not (exists login item "Hammerspoon") then
        make login item at end with properties {path:"/Applications/Hammerspoon.app", hidden:true, name:"Hammerspoon"}
    end if
end tell
EOF
echo "[ZoomChecker Installer] Hammerspoon added to login items."

# ---- 5. Launch Hammerspoon ----
echo "[ZoomChecker Installer] Launching Hammerspoon..."
open -a "Hammerspoon"

echo "[ZoomChecker Installer] Setup complete!"