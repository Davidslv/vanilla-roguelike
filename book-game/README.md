# Ruby Roguelike Game

A simple roguelike game built in Ruby using the Entity-Component-System (ECS) architecture. This project is created by following the book "Building Games with Ruby and ECS".

## Features

- Procedurally generated dungeons
- Turn-based gameplay
- ASCII graphics
- Inventory management
- Combat system
- Save and load functionality

## Installation

1. Make sure you have Ruby 3.2.2 installed
2. Clone this repository
3. Run `bundle install` to install dependencies

## Running the Game

To start the game, run:

```
ruby game.rb
```

## Controls

- Arrow keys: Move the player
- `i`: Open inventory
- `q`: Quit the game
- `s`: Save the game
- `l`: Load the game

## Testing

Run the test suite with:

```
bundle exec rspec
```

## Project Structure

- `lib/`: Contains the game code
  - `components/`: ECS components
  - `systems/`: ECS systems
  - `entity.rb`: Entity class
  - `world.rb`: World class
- `spec/`: Contains tests
- `game.rb`: Main game file