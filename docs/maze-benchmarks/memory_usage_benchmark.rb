#!/usr/bin/env ruby

require 'benchmark/memory'
require_relative '../../lib/vanilla/support/tile_type'
require_relative '../../lib/vanilla/map_utils/grid'
require_relative '../../lib/vanilla/algorithms'
require_relative './legacy_cell'

module Vanilla
  module Benchmarks
    class MemoryUsageBenchmark
      def self.run
        puts "Running Memory Usage Benchmark"
        puts "============================="
        puts "This benchmark compares memory usage between:"
        puts "1. Legacy Cell implementation (without Flyweight)"
        puts "2. New Cell implementation with Flyweight pattern"
        puts

        run_maze_creation_benchmark
        run_tile_setting_benchmark
        run_large_maze_benchmark
      end

      def self.run_maze_creation_benchmark
        puts "Benchmark: Creating a 50x50 maze"
        puts "--------------------------------"

        Benchmark.memory do |x|
          x.report("Legacy (without Flyweight)") do
            grid = Vanilla::MapUtils::LegacyGrid.new(rows: 50, columns: 50)
            Vanilla::Algorithms::BinaryTree.on(grid)
          end

          x.report("With Flyweight") do
            grid = Vanilla::MapUtils::Grid.new(rows: 50, columns: 50)
            Vanilla::Algorithms::BinaryTree.on(grid)
          end

          x.compare!
        end
        puts
      end

      def self.run_tile_setting_benchmark
        puts "Benchmark: Setting tiles in a 30x30 maze"
        puts "---------------------------------------"

        # Pre-create the grids
        legacy_grid = Vanilla::MapUtils::LegacyGrid.new(rows: 30, columns: 30)
        flyweight_grid = Vanilla::MapUtils::Grid.new(rows: 30, columns: 30)

        # Pre-generate random positions
        positions = 100.times.map { [rand(30), rand(30)] }
        tiles = [
          Vanilla::Support::TileType::EMPTY,
          Vanilla::Support::TileType::WALL,
          Vanilla::Support::TileType::PLAYER,
          Vanilla::Support::TileType::STAIRS
        ]

        Benchmark.memory do |x|
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

      def self.run_large_maze_benchmark
        puts "Benchmark: Creating a 100x100 grid (only grid creation, no algorithm)"
        puts "--------------------------------------------------------------------"

        Benchmark.memory do |x|
          x.report("Legacy (without Flyweight)") do
            Vanilla::MapUtils::LegacyGrid.new(rows: 100, columns: 100)
          end

          x.report("With Flyweight") do
            Vanilla::MapUtils::Grid.new(rows: 100, columns: 100)
          end

          x.compare!
        end
        puts
      end
    end
  end
end

if __FILE__ == $0
  Vanilla::Benchmarks::MemoryUsageBenchmark.run
end