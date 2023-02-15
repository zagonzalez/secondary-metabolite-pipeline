#!/bin/bash

# Run long (> 2 minutes) process
# Usage: source run_long_process.sh
# This will allow SIGTERM to be caught so that a message can be logged and cleanup performed
# Copyright 2022, SolareaBio
# Susan Corbett, May 2022

set -ex

# Run a command that may take longer than 2 minutes to complete
# Parameters:
#   Command
#   File for redirection of stdio (optional)
# Note: If quotes are required for a command parameter, pass in as colons (:)
run_long_process() {
    command=$(echo "$1" | sed 's/:/\"/g')
    redirect_file="$2"
    use_tee="$3"
    
    # Run the command in the background
    if [[ "$use_tee" == "True" ]]; then
        echo "run_long_process: Using tee to file"
        #$command 2>&1 | tee $redirect_file &
        eval "$command" 2>&1 | tee $redirect_file &
        child_pid="$!"
    elif [[ "$redirect_file" != "" ]]; then
        echo "run_long_process: Using redirect file"
        #$command > $redirect_file &
        eval "$command" > $redirect_file &
        child_pid="$!"
    else
        echo "run_long_process: NOT using redirect file"
        #$command &
        eval "$command" &
        child_pid="$!"
    fi
    
    # Wait for the process to complete
    wait "${child_pid}"
}