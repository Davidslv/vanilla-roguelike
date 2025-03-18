#!/usr/bin/env ruby

require 'benchmark/memory'
require_relative '../../lib/vanilla/support/tile_type'
require_relative '../../lib/vanilla/map_utils/grid'
require_relative './legacy_cell'

module Vanilla
  module Benchmarks
    class LargeGridBenchmark
      def self.run
        puts "Running Large Grid Memory Benchmark"
        puts "=================================="
        puts "This benchmark tests memory usage for very large grids"
        puts "to see if the Flyweight pattern shows more benefits at scale."
        puts

        # Gradually increase grid size to watch memory usage
        [100, 200, 500].each do |size|
          run_grid_creation_benchmark(size)
        end
      end

      def self.run_grid_creation_benchmark(size)
        puts "Benchmark: Creating a #{size}x#{size} grid"
        puts "-------------------------------#{'-' * size.to_s.length}"

        begin
          print "Legacy (without Flyweight): "
          mem_before = get_memory_usage
          grid = Vanilla::MapUtils::LegacyGrid.new(rows: size, columns: size)
          mem_after = get_memory_usage
          legacy_memory = mem_after - mem_before
          puts "#{legacy_memory.round(2)} MB"

          # Force garbage collection before next test
          grid = nil
          GC.start

          print "With Flyweight: "
          mem_before = get_memory_usage
          grid = Vanilla::MapUtils::Grid.new(rows: size, columns: size)
          mem_after = get_memory_usage
          flyweight_memory = mem_after - mem_before
          puts "#{flyweight_memory.round(2)} MB"

          puts "Ratio: #{(legacy_memory / flyweight_memory).round(2)}x"
          puts "Difference: #{(legacy_memory - flyweight_memory).round(2)} MB"
        rescue => e
          puts "Error: #{e.message}"
        end

        puts
      end

      def self.get_memory_usage
        # Get memory usage in MB
        `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
      end
    end
  end
end

if __FILE__ == $0
  Vanilla::Benchmarks::LargeGridBenchmark.run
end