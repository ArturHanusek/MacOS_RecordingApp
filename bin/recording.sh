#!/bin/bash

# set server address and port
SERVER="localhost"
PORT=8080

# check params
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 start|-stop [options]"
    exit 1
fi

# send command to tcp server
send_command() {
    local command="$1"
    echo "$command" "$@" | nc $SERVER $PORT
}

case "$1" in
    start)
        shift
        # send start command
        send_command "start $@"
        ;;
    stop)
        # send stop command
        send_command "stop"
        ;;
    *)
        echo "Invalid command. Use 'start' or 'stop'."
        exit 1
        ;;
esac
