#!/usr/bin/env ruby
# frozen_string_literal: true

# Graphical (Ruby2D) proof of concept for Vanilla Roguelike.
#
# This is a SECOND front-end for the exact same game engine the terminal uses.
# It proves the renderer/input abstraction: the ECS world, movement, combat and
# monster AI are untouched — only two seams are swapped:
#   * input  : Ruby2D key events -> InputHandler (instead of the blocking InputSystem)
#   * output : Renderers::Ruby2DScene -> Ruby2D shapes (instead of TerminalRenderer)
#
# Run it:
#   bundle install --with gui   # one-time: installs the ruby2d gem (needs SDL2)
#   ./bin/play_gui.rb --seed=12345
#
# Controls: arrow keys or h/j/k/l to move, f toggles FOV, q/escape quits.

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'vanilla'
require 'vanilla/game'
require 'optparse'

begin
  require 'ruby2d'
rescue LoadError
  abort <<~MSG
    Ruby2D is not installed. It is an optional dependency for this graphical POC.

      bundle install --with gui

    Ruby2D needs SDL2 native libraries. On macOS:
      brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf
    The terminal game (./bin/play.rb) works without any of this.
  MSG
end

# --- Options ---------------------------------------------------------------
options = { seed: Random.new_seed, difficulty: 1 }
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('--seed=SEED', Integer, 'Set random seed') { |s| options[:seed] = s }
  opts.on('--difficulty=LEVEL', Integer, 'Difficulty 1-5') { |l| options[:difficulty] = l }
  opts.on('--dev-mode', 'Disable fog of war') { options[:dev_mode] = true }
end.parse!

# --- Layout & palette ------------------------------------------------------
TILE = 36
MARGIN = 16
HEADER_H = 96
GLYPH_COLORS = {
  Vanilla::Support::TileType::PLAYER => '#2ecc71', # green
  Vanilla::Support::TileType::MONSTER => '#e74c3c', # red
  Vanilla::Support::TileType::STAIRS => '#3498db', # blue
  Vanilla::Support::TileType::GOLD => '#f1c40f', # yellow
  Vanilla::Support::TileType::DRAGON => '#e67e22' # orange
}.freeze
FLOOR_VISIBLE  = '#2c3e50'
FLOOR_EXPLORED = '#161c22'
WALL_COLOR     = '#95a5a6'
HUD_COLOR      = '#ecf0f1'

# --- Build the world (no terminal input/render systems) --------------------
game = Vanilla::Game.new(seed: options[:seed], difficulty: options[:difficulty], dev_mode: options[:dev_mode])
world = game.world
world.systems.reject! do |system, _priority|
  system.is_a?(Vanilla::Systems::InputSystem) || system.is_a?(Vanilla::Systems::RenderSystem)
end

srand(options[:seed])
maze_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }&.first
maze_system&.update(nil)
fov_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::FOVSystem) }&.first
fov_system&.update(nil)
input_handler = Vanilla::InputHandler.new(world)

scene = Vanilla::Renderers::Ruby2DScene.build(world, seed: options[:seed])
abort 'Could not build the initial scene (no grid).' unless scene

set title: 'Vanilla Roguelike (Ruby2D POC)',
    background: '#0d1117',
    width: (scene.columns * TILE) + (2 * MARGIN),
    height: HEADER_H + (scene.rows * TILE) + MARGIN

# --- Drawing ---------------------------------------------------------------
def tile_origin(row, col)
  [MARGIN + (col * TILE), HEADER_H + (row * TILE)]
end

def draw_hud(hud)
  pct = hud.hp && hud.max_hp ? (hud.hp.to_f / hud.max_hp * 100).round : 0
  algorithm = hud.algorithm.to_s.split('::').last
  Text.new("Vanilla Roguelike  |  Seed: #{hud.seed}  |  Level: #{hud.difficulty}",
           x: MARGIN, y: 16, size: 18, color: HUD_COLOR)
  Text.new("HP: #{hud.hp}/#{hud.max_hp} (#{pct}%)   #{hud.rows}x#{hud.columns}   #{algorithm}",
           x: MARGIN, y: 44, size: 16, color: HUD_COLOR)
  Text.new('move: arrows / hjkl    f: toggle FOV    q: quit',
           x: MARGIN, y: 70, size: 14, color: '#7f8c8d')
end

def draw_scene(scene)
  draw_hud(scene.hud)

  scene.tiles.each do |tile|
    next if tile.state == :hidden

    x, y = tile_origin(tile.row, tile.column)
    floor = tile.state == :visible ? FLOOR_VISIBLE : FLOOR_EXPLORED
    Square.new(x: x, y: y, size: TILE - 1, color: floor)

    color = GLYPH_COLORS[tile.glyph]
    next unless color && tile.state == :visible

    Text.new(tile.glyph, x: x + (TILE / 3), y: y + (TILE / 6), size: TILE - 8, color: color)
  end

  scene.walls.each do |wall|
    x, y = tile_origin(wall.row, wall.column)
    if wall.side == :east
      Line.new(x1: x + TILE - 1, y1: y, x2: x + TILE - 1, y2: y + TILE, width: 2, color: WALL_COLOR)
    else
      Line.new(x1: x, y1: y + TILE - 1, x2: x + TILE, y2: y + TILE - 1, width: 2, color: WALL_COLOR)
    end
  end
end

def redraw(world, seed)
  clear
  scene = Vanilla::Renderers::Ruby2DScene.build(world, seed: seed)
  draw_scene(scene) if scene
end

# --- Input -> game step ----------------------------------------------------
KEY_MAP = {
  'up' => 'k', 'down' => 'j', 'left' => 'h', 'right' => 'l',
  'w' => 'k',  's' => 'j',    'a' => 'h',    'd' => 'l',
  'k' => 'k',  'j' => 'j',    'h' => 'h',    'l' => 'l',
  'f' => 'f'
}.freeze

redraw(world, options[:seed])

on :key_down do |event|
  key = event.key
  if %w[q escape].include?(key)
    close
  elsif (mapped = KEY_MAP[key])
    input_handler.handle_input(mapped) # queue movement / FOV-toggle command
    world.update(nil)                  # run systems, execute the command, fire events
    fov_system&.update(nil)            # refresh fog of war for the new frame
    redraw(world, options[:seed])
  end
end

show
