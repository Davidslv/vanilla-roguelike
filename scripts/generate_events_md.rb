#!/usr/bin/env ruby
# frozen_string_literal: true

# scripts/generate_events_md.rb
require 'fileutils'
require_relative '../lib/vanilla/events/types'

# Generate events.md from Types::EVENTS
FileUtils.mkdir_p('documents') unless Dir.exist?('documents')
File.open('documents/events.md', 'w') do |file|
  file.puts "# Event System Documentation"
  file.puts
  file.puts "## Core Game Events"
  file.puts

  Vanilla::Events::Types::EVENTS.each do |key, event|
    file.puts "### #{key.to_s.upcase}"
    file.puts "- **Type**: `#{event.name}`"
    file.puts "- **Description**: #{event.description}"
    file.puts "- **Data**: #{event.data}"
    file.puts
  end
end

puts "Generated documents/events.md with #{Vanilla::Events::Types::EVENTS.size} events"
