#!/usr/bin/env ruby

# Runner for all maze benchmarks
# Usage: ruby docs/maze-benchmarks/run_all.rb

puts "==========================================="
puts "VANILLA MAZE GENERATION BENCHMARKS"
puts "==========================================="
puts

# Run memory benchmark
puts "Running memory usage benchmark..."
require_relative './memory_usage_benchmark'
Vanilla::Benchmarks::MemoryUsageBenchmark.run

puts "\n===========================================\n\n"

# Run performance benchmark
puts "Running performance benchmark..."
require_relative './performance_benchmark'
Vanilla::Benchmarks::PerformanceBenchmark.run

puts "\n===========================================\n\n"

# Run large grid benchmark
puts "Running large grid benchmark..."
require_relative './large_grid_benchmark'
Vanilla::Benchmarks::LargeGridBenchmark.run

puts "\n===========================================\n"
puts "All benchmarks completed!"
puts "See results above for comparison between legacy and Flyweight implementations"