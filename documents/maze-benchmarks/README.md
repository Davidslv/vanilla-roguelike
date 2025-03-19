# Maze Generation Benchmarks

This directory contains benchmarks for the maze generation system in Vanilla.

## Overview

The benchmarks in this directory focus on measuring the performance improvements
achieved by implementing the Flyweight pattern for cell types in the maze generation
system. The Flyweight pattern reduces memory usage by sharing common state across
multiple cell instances.

## Running Benchmarks

To run all benchmarks:

```bash
ruby docs/maze-benchmarks/run_all.rb
```

To run a specific benchmark:

```bash
ruby docs/maze-benchmarks/memory_benchmark.rb
```

## Benchmark Descriptions

1. **Memory Usage**: Measures the memory footprint of creating large mazes with and without the Flyweight pattern.
2. **Creation Time**: Measures the time required to create mazes of various sizes.
3. **Pathfinding Performance**: Measures the impact of the Flyweight pattern on pathfinding algorithms.
4. **Cell Type Access Speed**: Compares the performance of accessing cell type properties directly vs. through the Flyweight.
5. **Large Maze Stress Test**: Tests how the system handles extremely large mazes.
6. **Algorithm Comparison**: Compares different maze generation algorithms with the Flyweight pattern.
7. **Spatial Query Performance**: Measures performance of spatial queries on the grid.
8. **Serialization Size**: Compares serialization size with and without the Flyweight pattern.
9. **Deserialization Speed**: Measures how quickly mazes can be deserialized.
10. **Memory Allocation Pattern**: Analyzes object allocation patterns during maze operations.

## Creating New Benchmarks

To add a new benchmark:

1. Create a new Ruby file in this directory
2. Follow the pattern established in existing benchmarks:
   - Use the benchmark-memory gem for memory benchmarks
   - Use the benchmark-ips gem for speed benchmarks
   - Include clear comparison metrics
3. Update this README to document your new benchmark

## Interpreting Results

The benchmark outputs include:

- **Memory Usage**: Reported in MB or KB
- **Speed**: Reported in iterations per second
- **Comparison Ratios**: How much better/worse one approach is compared to another

A higher ratio for speed benchmarks means faster performance. For memory benchmarks,
a lower memory usage indicates better performance.