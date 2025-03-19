#!/usr/bin/env ruby

require 'benchmark/ips'
require_relative '../../lib/vanilla/support/tile_type'
require_relative '../../lib/vanilla/map_utils/grid'
require_relative './legacy_cell'

module Vanilla
  module Benchmarks
    class PerformanceBenchmark
      def self.run
        puts "Running Performance Benchmark"
        puts "============================="
        puts "This benchmark compares performance between:"
        puts "1. Legacy Cell implementation (without Flyweight)"
        puts "2. New Cell implementation with Flyweight pattern"
        puts

        run_creation_benchmark
        run_tile_setting_benchmark
        run_property_access_benchmark
      end

      def self.run_creation_benchmark
        puts "Benchmark: Creating a 20x20 maze"
        puts "--------------------------------"

        Benchmark.ips do |x|
          x.config(time: 5, warmup: 2)

          x.report("Legacy (without Flyweight)") do
            Vanilla::MapUtils::LegacyGrid.new(rows: 20, columns: 20)
          end

          x.report("With Flyweight") do
            Vanilla::MapUtils::Grid.new(rows: 20, columns: 20)
          end

          x.compare!
        end
        puts
      end

      def self.run_tile_setting_benchmark
        puts "Benchmark: Setting 100 random tiles"
        puts "---------------------------------"

        # Pre-create the grids
        legacy_grid = Vanilla::MapUtils::LegacyGrid.new(rows: 30, columns: 30)
        flyweight_grid = Vanilla::MapUtils::Grid.new(rows: 30, columns: 30)

        # Pre-generate random positions and tiles
        positions = 100.times.map { [rand(30), rand(30)] }
        tiles = [
          Vanilla::Support::TileType::EMPTY,
          Vanilla::Support::TileType::WALL,
          Vanilla::Support::TileType::PLAYER,
          Vanilla::Support::TileType::STAIRS
        ]

        Benchmark.ips do |x|
          x.config(time: 5, warmup: 2)

          x.report("Legacy (without Flyweight)") do
            positions.each do |row, col|
              cell = legacy_grid[row, col]
              cell.tile = tiles.sample if cell
            end
          end

          x.report("With Flyweight") do
            positions.each do |row, col|
              cell = flyweight_grid[row, col]
              cell.tile = tiles.sample if cell
            end
          end

          x.compare!
        end
        puts
      end

      def self.run_property_access_benchmark
        puts "Benchmark: Accessing cell properties"
        puts "----------------------------------"

        # Pre-create the grids and set some tiles
        legacy_grid = Vanilla::MapUtils::LegacyGrid.new(rows: 20, columns: 20)
        flyweight_grid = Vanilla::MapUtils::Grid.new(rows: 20, columns: 20)

        positions = 50.times.map { [rand(20), rand(20)] }

        # Set some tiles to player and stairs
        positions.each do |row, col|
          legacy_cell = legacy_grid[row, col]
          flyweight_cell = flyweight_grid[row, col]

          if legacy_cell && flyweight_cell
            tile = [
              Vanilla::Support::TileType::PLAYER,
              Vanilla::Support::TileType::STAIRS,
              Vanilla::Support::TileType::WALL,
              Vanilla::Support::TileType::EMPTY
            ].sample

            legacy_cell.tile = tile
            flyweight_cell.tile = tile
          end
        end

        Benchmark.ips do |x|
          x.config(time: 5, warmup: 2)

          x.report("Legacy (without Flyweight)") do
            positions.each do |row, col|
              cell = legacy_grid[row, col]
              if cell
                # Check tile-based properties
                player = cell.tile == Vanilla::Support::TileType::PLAYER
                stairs = cell.tile == Vanilla::Support::TileType::STAIRS
                walkable = cell.tile != Vanilla::Support::TileType::WALL
              end
            end
          end

          x.report("With Flyweight") do
            positions.each do |row, col|
              cell = flyweight_grid[row, col]
              if cell
                # Call the delegated methods
                player = cell.player?
                stairs = cell.stairs?
                walkable = cell.cell_type.walkable?
              end
            end
          end

          x.compare!
        end
        puts
      end
    end
  end
end

if __FILE__ == $0
  Vanilla::Benchmarks::PerformanceBenchmark.run
end