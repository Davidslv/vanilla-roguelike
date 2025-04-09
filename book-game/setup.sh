#!/bin/bash

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run the game
ruby game.rb