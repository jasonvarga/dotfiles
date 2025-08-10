#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Reload Hammerspoon Config
# @raycast.mode compact
# @raycast.icon /Applications/Hammerspoon.app/Contents/Resources/AppIcon.icns

# Reloading would result in an error, but Hammerspoon says it's expected if
# it's reloading, which is exactly what we're doing. It stills returns an
# error code so we will return true to avoid Raycast showing an error.
hs -c "hs.reload()" 2>/dev/null || true