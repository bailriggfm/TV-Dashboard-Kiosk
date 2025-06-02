#!/bin/bash

# Function to set the latest sink as the default
set_latest_sink_as_default() {
    # Get the ID of the most recently added sink
    latest_sink=$(pactl list short sinks | tail -n 1 | awk '{print $1}')

    if [ -n "$latest_sink" ]; then
        echo "Setting sink $latest_sink as default"
        pactl set-default-sink "$latest_sink"

        # Set volume to 100% and unmute
        pactl set-sink-volume "$latest_sink" 100%
        pactl set-sink-mute "$latest_sink" 0
    else
        echo "No sinks found to set as default"
    fi
}

# Initial setup
sleep 1
set_latest_sink_as_default

# Monitor for device changes
pactl subscribe | grep --line-buffered "sink" | while read -r line; do
    if [[ "$line" == *"new"* ]]; then
        echo "New audio device detected"
        sleep 1
        set_latest_sink_as_default
    fi
done