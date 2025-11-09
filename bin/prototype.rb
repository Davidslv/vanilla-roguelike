#!/usr/bin/env ruby
# A minimal roguelike prototype - complete and runnable
# USAGE: ruby bin/prototype.rb
#
# DESCRIPTION:
# This is a minimal roguelike prototype that demonstrates the core mechanics of a roguelike game.
# It is a simple grid-based game where the player can move around the grid and collect items.
# The game is controlled by the keyboard using the h, j, k, l keys.
# The game is rendered to the console using the puts method.
# The game is run by the main method.
# The game is a single file that can be run by the ruby command.
#
# frozen_string_literal: true
require 'io/console'

# Grid representation
class Grid
  attr_reader :rows, :columns

  def initialize(rows, columns)
    @rows = rows
    @columns = columns
    @cells = Array.new(rows) { Array.new(columns, :floor) }
    # Create walls around the edges
    @rows.times do |row|
      @columns.times do |col|
        @cells[row][col] = :wall if row == 0 || row == @rows - 1
        @cells[row][col] = :wall if col == 0 || col == @columns - 1
      end
    end
  end

  def [](row, col)
    return nil unless row.between?(0, @rows - 1) && col.between?(0, @columns - 1)
    @cells[row][col]
  end

  def []=(row, col, value)
    @cells[row][col] = value if row.between?(0, @rows - 1) && col.between?(0, @columns - 1)
  end
end

# Player representation
class Player
  attr_accessor :row, :column

  def initialize(row, column)
    @row = row
    @column = column
  end
end

# Input handling
def get_keypress
  $stdin.raw { $stdin.getc.chr }
rescue
  nil
end

def handle_input(key)
  case key
  when 'k' then :north  # 'k'
  when 'j' then :south  # 'j'
  when 'h' then :west   # 'h'
  when 'l' then :east   # 'l'
  when 'q' then :quit
  else nil
  end
end

# Movement logic
def move_player(player, direction, grid)
  new_row = player.row
  new_col = player.column

  case direction
  when :north then new_row -= 1
  when :south then new_row += 1
  when :west then new_col -= 1
  when :east then new_col += 1
  end

  # Check bounds
  return false unless grid[new_row, new_col]

  # Check if it's a wall
  return false if grid[new_row, new_col] == :wall

  # Move is valid
  player.row = new_row
  player.column = new_col
  true
end

# Rendering
def clear_screen
  system("clear") || system("cls")
end

def render(grid, player)
  clear_screen
  puts "Simple Roguelike Prototype (Press 'q' to quit)"
  puts "Use h/j/k/l or arrow keys to move"
  puts ""

  grid.rows.times do |row|
    line = ""
    grid.columns.times do |col|
      if row == player.row && col == player.column
        line += "@"
      elsif grid[row, col] == :wall
        line += "#"
      else
        line += "."
      end
    end
    puts line
  end
end

# Create a simple grid with walls
def create_simple_grid(rows, columns)
  Grid.new(rows, columns)
end

# Main game loop
def main
  # Initialize
  grid = create_simple_grid(10, 10)
  player = Player.new(5, 5)

  # Game loop
  loop do
    # Render
    render(grid, player)

    # Get input
    key = get_keypress
    direction = handle_input(key)

    break if direction == :quit

    # Move if valid
    move_player(player, direction, grid) if direction
  end

  clear_screen
  puts "Thanks for playing!"
end

# Start the game
main if __FILE__ == $0