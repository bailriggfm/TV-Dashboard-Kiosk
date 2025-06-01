#!/bin/bash

# Wait a moment for audio system to initialize
sleep 2

# Set the default sink (speaker) volume to 100%
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0

# Unmute the default sink if it's muted
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0

exit 0