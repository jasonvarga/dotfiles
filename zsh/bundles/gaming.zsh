is_steam_running() {
    if osascript -e 'tell application "System Events" to (name of processes) contains "Steam Helper"' | grep -q "true"; then
        echo "✅ Steam is running"
        return 0
    else
        echo "❌ Steam is not running"
        return 1
    fi
}

run_with_steam() {
    local script_path="$1"
    local max_attempts=15
    local attempt=0
    local success=1

    # Validate script path is provided
    if [[ -z "$script_path" ]]; then
        echo "Error: No script path provided" >&2
        return 1
    fi

    while [[ $attempt -lt $max_attempts ]]; do
        # Check if Steam is running
        if is_steam_running; then
            # Attempt to run the script
            "$script_path"
            success=$?
            break
        fi

        # If Steam is not running, try to launch it
        if [[ $attempt -eq 0 ]]; then
            open -a Steam
        fi

        # Wait before next check
        sleep 2
        ((attempt++))
    done

    return $success
}