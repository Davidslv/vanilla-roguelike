#!/usr/bin/env ruby

puts "Cleaning up event logs..."
system("rm event_logs/*.jsonl")
puts "Cleaning up logs..."
system("rm logs/*.log")

puts "Cleaning up coverage..."
system("rm -rf coverage")

puts "Cleaning up logs..."
system("rm logs/test/*.log")
