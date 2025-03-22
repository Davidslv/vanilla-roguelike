#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to reset terminal state
reset_terminal() {
  echo -e "${BLUE}Resetting terminal state...${NC}"
  # Reset terminal to sane state
  stty sane
  # Clear screen
  clear
}

# Make sure we reset terminal state on exit
trap reset_terminal EXIT

# Reset terminal at the beginning
reset_terminal

# Make sure logs directory exists
mkdir -p logs/development
LOG_FILE="logs/vanilla_game_$(date +%Y%m%d_%H%M%S).log"

# Set up environment
export VANILLA_DEBUG=true

echo -e "${GREEN}=== Vanilla Roguelike Game ===${NC}"
echo -e "${YELLOW}This game uses ECS architecture${NC}"
echo -e "${BLUE}Controls:${NC}"
echo " - Arrow keys or HJKL: Move"
echo " - Q: Quit game"
echo " - CTRL+C: Force exit"
echo
echo -e "${YELLOW}Logging to:${NC} $LOG_FILE"
echo

# Run the game with proper terminal mode
ruby -e '
  begin
    # Configure terminal for game
    system("stty raw -echo")

    # Run the game
    load "bin/run_clean_ecs.rb"
  rescue => e
    # Print error information when something goes wrong
    system("stty sane")
    puts "\n\nERROR: #{e.class}: #{e.message}"
    puts e.backtrace
  ensure
    # Always restore terminal state
    system("stty sane")
  end
' 2>&1 | tee $LOG_FILE

echo -e "${GREEN}Game session ended${NC}"
echo -e "${BLUE}See ${LOG_FILE} for logs${NC}"

# No need to reset here - the trap will handle it