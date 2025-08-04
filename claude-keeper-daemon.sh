#!/bin/bash
# Claude Keeper Daemon - Simple scheduler with cron expression support

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_DIR="$HOME/logs"

# Default schedule if config.json doesn't exist or has no schedule
DEFAULT_SCHEDULE="30 0,4-23 * * *"

# Create log directory if it doesn't exist
if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR"
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DAEMON] $1"
}

# Get schedule from config.json
get_schedule() {
    if [[ -f "$CONFIG_FILE" ]] && command -v node >/dev/null 2>&1; then
        local schedule=$(node -e "
            try {
                const config = JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'));
                console.log(config.schedule || '');
            } catch (e) {
                console.log('');
            }
        " 2>/dev/null)
        
        if [[ -n "$schedule" ]]; then
            echo "$schedule"
        else
            echo "$DEFAULT_SCHEDULE"
        fi
    else
        echo "$DEFAULT_SCHEDULE"
    fi
}

# Simple cron parser for common patterns
# Returns seconds until next run
calculate_next_run() {
    local schedule="$1"
    local now=$(date +%s)
    local current_minute=$(date +%M | sed 's/^0//')
    local current_hour=$(date +%H | sed 's/^0//')
    
    # Parse cron fields: minute hour day month weekday
    IFS=' ' read -r minute hour day month weekday <<< "$schedule"
    
    # Handle minute field
    local next_minute
    if [[ "$minute" == "*" ]]; then
        next_minute=$current_minute
    elif [[ "$minute" =~ ^[0-9]+$ ]]; then
        next_minute=$minute
    else
        # Default to minute value for complex patterns
        next_minute=30
    fi
    
    # Handle hour field - focus on the most common patterns
    local next_hour
    if [[ "$hour" == "*" ]]; then
        next_hour=$current_hour
    elif [[ "$hour" =~ ^[0-9]+$ ]]; then
        next_hour=$hour
    elif [[ "$hour" == "0,4-23" ]]; then
        # Special case for our default schedule
        if [[ $current_hour -eq 0 ]] || [[ $current_hour -ge 4 ]]; then
            next_hour=$((current_hour + 1))
            if [[ $next_hour -gt 23 ]]; then
                next_hour=0
            fi
        else
            next_hour=4
        fi
    elif [[ "$hour" =~ ^[0-9]+-[0-9]+$ ]]; then
        # Simple range like 9-17
        local start=${hour%-*}
        local end=${hour#*-}
        if [[ $current_hour -ge $start && $current_hour -le $end ]]; then
            next_hour=$((current_hour + 1))
            if [[ $next_hour -gt $end ]]; then
                next_hour=$start
            fi
        else
            next_hour=$start
        fi
    else
        # Default to every hour for complex patterns
        next_hour=$((current_hour + 1))
        if [[ $next_hour -gt 23 ]]; then
            next_hour=0
        fi
    fi
    
    # Calculate target time
    local current_seconds=$((current_hour * 3600 + current_minute * 60))
    local target_seconds=$((next_hour * 3600 + next_minute * 60))
    
    # If target is in the past, add 24 hours
    if [[ $target_seconds -le $current_seconds ]]; then
        target_seconds=$((target_seconds + 86400))
    fi
    
    echo $((target_seconds - current_seconds))
}

# Run claude-keeper
run_keeper() {
    echo ""
    echo ""
    echo ""
    echo ""

    log "Running claude-keeper..."
    cd "$SCRIPT_DIR"
    
    if command -v node >/dev/null 2>&1; then
        node "$SCRIPT_DIR/claude-keeper"
    else
        log "ERROR: Node.js not found in PATH"
        return 1
    fi
    
    log "claude-keeper completed"
}

# Main daemon loop
main() {
    local schedule=$(get_schedule)
    
    log "Starting Claude Keeper Daemon (PID: $$)"
    log "Schedule: $schedule"
    echo ""
    
    while true; do
        run_keeper
        
        local sleep_seconds=$(calculate_next_run "$schedule")
        local next_run_time=$(date -d "+${sleep_seconds} seconds" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        
        # Fallback for macOS
        if [[ -z "$next_run_time" ]]; then
            next_run_time=$(date -v+${sleep_seconds}S '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        fi
        
        log "Sleeping for $sleep_seconds seconds until next run: $next_run_time"
        sleep "$sleep_seconds"
    done
}

# Handle signals gracefully
trap 'log "Daemon shutting down..."; exit 0' TERM INT

# Run main function
main